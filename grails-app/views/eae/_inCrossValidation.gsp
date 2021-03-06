<mark>Step:</mark> Drop a High dimensional variable into this window.<br/>

<div id='description' class="txt">
    This Workflow triggers a cross validation workflow coupled with a model builder algrorithm.
</div>

<div id='highDimDataBox' class="txt">
    <table id="inputeDataTable">
        <tr>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                <form method="post" action="">
                    <div id='highDimDataCV' class="queryGroupIncludeSmall"></div>
                </form>
                <input type="button" class='txt' onclick="clearVarSelection('highDimDataCV')" value="Clear Window">
                <input
                        id="submitCV"
                        class='txt flatbutton'
                        type="button"
                        value="Run CV"
                        onclick="triggerCV()"/>
            </td>
        </tr>
        <tr>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                Select the algorithm to use <br/>
                <div class="algorithmToUse">
                    <select id='AlgoList'>
                        <option value="LassoWithSGD">Lasso with Steepest Gradient Descent</option>
                        <option value="LinearRegressionWithSGD">Linear Regression</option>
                        <option value="LogisticRegressionWithLBFGS">Logistic Regression with Broyden–Fletcher–Goldfarb–Shannon</option>
                        <option value="LogisticRegressionWithSGD">Logistic Regression with Steepest Gradient Descent</option>
                        <option value="SVM">Support Vector Machine (SVM)</option>
                    </select>
                </div>
            </td>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                Select the number folds for the cross validation <br/>
                <select id='kFoldsOptions'>
                    <option value="0.33">3-fold</option>
                    <option value="0.2">5-fold</option>
                    <option value="0.1">10-fold</option>
                </select>
            </td>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                Select the number resamplings <br/>
                <select id='resamplingNumber'></select>
            </td>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                Select the percentage of features  to remove at every iteration <br/>
                <select id='numberOfFeaturesToRemove'></select>
            </td>
            <td style='padding-right: 2em; padding-bottom: 1em'>
                <div class="peCheckBox"></div>
                Do a pathway enrichment<br>
                <input type="checkbox" id="addPE" checked>
            </td>
        </tr>
    </table>
</div>
<br/>

<hr class="myhr"/>
<div id="cacheTableDiv">
    <table id="mongocachetable" class ="cachetable"></table>
    <div id="emptyCache">There is no prior computation to display in the history.</div>
    <button type="button"
            value="refreshCacheDiv"
            onclick="refreshCVCache()"
            class="flatbutton">Refresh</button>
</div>

<script>
    var currentWorkflow = "CrossValidation";
    populateCacheDIV(currentWorkflow);
    activateDragAndDropEAE('highDimDataCV');
    fillResamplingOption();
    fillFeaturesToRemoveOption();

    function register() {
        registerConceptBoxEAE('highDimDataCV', [1, 2], 'hleaficon', 1, 1);
    }

    function triggerCV() {
        registerWorkflowParams(currentWorkflow);
        runWorkflow();
    }

    function refreshCVCache(){
        populateCacheDIV(currentWorkflow);
    }

    function customSanityCheck() {
        return true;
    }

    function cacheDIVCustomName(job){
        var name = "HighDim Data: " + job.workflowdata + "\<br /> cohort 1 : " + job.patientids_cohort1 + "\<br /> cohort 2 : " + job.patientids_cohort2;
        var holder =  $('<td/>');
        holder.html(name);
        return {
            holder: holder,
            name: name
        };
    }

    function customWorkflowParameters(){
        var data = [];
        var algorithmToUse = $('#AlgoList').val();
        var kfold = $('#kFoldsOptions').val();
        var resampling =  $('#resamplingNumber').val();
        var numberOfFeaturesToRemove = $('#numberOfFeaturesToRemove').val();
        var doEnrichement = $('#addPE').is(":checked");
        var workflowSpecificParameters = algorithmToUse + " " + kfold + " " + resampling + " " +  numberOfFeaturesToRemove;
        data.push({name: 'workflowSpecificParameters', value: workflowSpecificParameters});
        data.push({name: 'doEnrichement', value: doEnrichement});
        return data;
    }

    function prepareDataForMongoRetrievale(currentworkflow, cacheQuery) {
        var tmpData = [];
        var splitTerms = cacheQuery.split('<br />');
        $.each(splitTerms, function (i, e) {
            var chunk = e.split(':');
            tmpData.push(chunk[1].trim());
        });
        var data = {
            Workflow: currentworkflow,
            WorkflowData: tmpData[0],
            patientids_cohort1: tmpData[1],
            patientids_cohort2: tmpData[2]
        };
        return data;
    }

    /**
     *   Display the result retieved from the cache
     *   @param jsonRecord
     */
    function buildOutput(jsonRecord){
        var _o = $('#eaeoutputs');

        var startdate = new Date(jsonRecord.StartTime.$date);
        var endDate = new Date(jsonRecord.EndTime.$date);
        var duration = (endDate - startdate)/1000;

        _o.append($('<table/>').attr("id","cvtable").attr("class", "cachetable")
                .append($('<tr/>')
                        .append($('<th/>').text("Algorithm used"))
                        .append($('<th/>').text("Iterations step"))
                        .append($('<th/>').text("Resampling"))
                        .append($('<th/>').text("Computation time"))
                ));
        $('#cvtable').append($('<tr/>')
                .append($('<td/>').text(jsonRecord.AlgorithmUsed))
                .append($('<td/>').text(jsonRecord.NumberOfFeaturesToRemove*100 + '%'))
                .append($('<td/>').text(jsonRecord.Resampling))
                .append($('<td/>').text(duration+ 's'))
        );

        _o.append($('<table/>').attr('id', "cvInfo").attr("class", "cvInfo" )
                .append($('<th/>').text("Performance Graph"))
                .append($('<th/>').text("Best Model characteristics"))
                .append($('<tr/>')
                        .append($('<td/>').append($('<div/>').attr('id', "cvPerformanceGraph").attr("class", "CrossValidation")))
                        .append($('<td/>').append($('<table/>').attr("id","modeltable").attr("class", "modeltable")
                                .append($('<tr/>')
                                        .append($('<th/>').text("Model Features"))
                                        .append($('<th/>').text("Weight"))
                                )))));

        var _h = $('#modeltable');
        $.each(jsonRecord.ModelFeatures, function (i, e) {
            _h.append($('<tr/>')
                    .append($('<td/>').text(e))
                    .append($('<td/>').text(jsonRecord.ModelWeights[i])));
        });


        var chart = scatterPlot()
                .x(function(d) {
                    return +d.x;
                })
                .y(function(d) {
                    return +d.y;
                })
                .height(250);

        d3.select('#cvPerformanceGraph').datum(formatData(jsonRecord.PerformanceCurve)).call(chart);
        tablePad('#modeltable', 2);
        tableSort('#modeltable');
    }

    function fillResamplingOption(){
        var _select = $('#resamplingNumber');
        var i;
        for (i=1;i<=10;i++){
            _select.append($('<option></option>').val(i).html(i))
        }
    }

    function fillFeaturesToRemoveOption(){
        var _select = $('#numberOfFeaturesToRemove');
        var i;
        for (i=1;i<=50;i++){
            _select.append($('<option></option>').val(i/100).html(i))
        }
    }
    
</script>