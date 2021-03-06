package eae.plugin
import com.mongodb.BasicDBObject
import grails.transaction.Transactional
import groovyx.net.http.AsyncHTTPBuilder
import org.json.JSONObject

import static groovyx.net.http.ContentType.*
import static groovyx.net.http.Method.GET
import static groovyx.net.http.Method.POST

@Transactional
class EaeService {

    def mongoCacheService

    /**
     *   Renders the default view
     */
    def getHpcScriptList() {
        def scriptList = ['Cross Validation', 'General Testing', 'Pathway Enrichment']
        return scriptList
    }

    /**
     *
     * @param params
     * @param workflow
     * @param MONGO_URL
     * @param mongoUser
     * @param database
     * @param password
     * @param username
     * @return
     */
    def customPreProcessing(params, workflow, MONGO_URL, mongoUser, database, password, username){
        switch (workflow){
            case "CrossValidation":
                return cvPreprocessing(params, MONGO_URL ,mongoUser, database, password, username);
            default:
                throw new Exception("The workflow in customPreProcessing doesn't exist.")
        }
    }

    /**
     * Sets all required parameters for the cross validation pipeline.
     * @param params
     * @param MONGO_URL
     * @param MONGO_PORT
     * @param database
     * @param username
     * @return {LinkedHashMap}
     *
     */
    private def cvPreprocessing(params, MONGO_URL, mongoUser, database, password, username){
        String workflowSpecificParameters = params.workflowSpecificParameters;
        def workflowParameters = [:];
        String mongoDocumentIDPE = "abcd0000" ;// fake mongoId
        Boolean doEnrichment = ((String)params.doEnrichement).toBoolean();

        if(doEnrichment){
            def query = new BasicDBObject("StudyName" , "PathwayEnrichment")
            query.append("DataType","None")
            query.append("CustomField","")
            query.append("WorkflowSpecificParameters","Bonferroni")
            mongoDocumentIDPE = mongoCacheService.initJob(MONGO_URL, mongoUser, database, password, "PathwayEnrichment", "NoSQL", username, query);
        }

        workflowParameters['workflow'] = params.workflow;
        workflowParameters['workflowSpecificParameters'] = workflowSpecificParameters + " " +  doEnrichment.toString() + " " + mongoDocumentIDPE.toString();

        return workflowParameters;
    }

    def customPostProcessing(result, workflow) {
        switch (workflow){
            case "PathwayEnrichment":
                return pePostProcessing(result);
            default:
                return result
        }
    }

    /**
     * This custom post processing is the only way to retrieve in real time the required data from KEGG
     * @param result
     * @return
     */
    private def pePostProcessing(result) {
        def topPathway = result.get('TopPathways').get(0).get(0)
        def url = "http://www.kegg.jp/pathway/" ;
        def listOfGenesIDs = result.get('ListOfGenesIDs').split(" ");

        def httpBuilder = new AsyncHTTPBuilder([uri: url, poolSize: 10, contentType: HTML])

        def keggPageHTML = httpBuilder.request(GET,TEXT) { req ->
            def finalUri = topPathway;
            for (int i = 0; i < listOfGenesIDs.size(); i++) {
                finalUri += "+" + listOfGenesIDs[i]
            }
            uri.path = finalUri // overrides any path in the default URL

            response.success = { resp, reader ->
                assert resp.status == 200
                reader.text
            }

            // called only for a 404 (not found) status code:
            response.'404' = { resp ->
                println 'Not found'
            }
        }

        result.put("KeggHTML", keggPageHTML.get());

        return result;
    }

    /**
     * This methods handles the remote submission to the eAEIterface which in return will trigger the Spark Job
     * I had to define all the queries manuall as the default rest plugin overrides some marshallers which causes massive
     * problem with tranSMART.
     * @param interfaceURL
     * @param paramMap
     * @return {str} : status of the submission
     */
    def eaeInterfaceSparkSubmit(String interfaceURL, Map paramMap ){
        //"https://146.169.15.140:8081/interfaceEAE/transmart/runSubmit"
        def httpBuilder = RestServiceFactory.initializeHttpBuilder(interfaceURL)
        def jsonBody = new JSONObject(paramMap).toString();
        def sparkSubmitStatus = httpBuilder.request(POST,TEXT) { req ->
            uri.path = "interfaceEAE/transmart/runSubmit" // overrides any path in the default URL
            body = jsonBody
            response.success = { resp, reader ->
                assert resp.status == 200
                reader.text
            }

            // called only for a 404 (not found) status code:
            response.'404' = { resp ->
                println '404 - Not found'
            }

            response.failure = { resp, text ->
                println("eAE - Error (${resp.status}) :: $text")
            }
        }

        return sparkSubmitStatus.get()
    }
}
