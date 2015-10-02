
<div id='clinicalData' class="txt">
    This Workflow triggers a pathway enrichment from a list of genes. It uses Fisher's exact test and bonferroni.
</div>

<div id='genesList' class="txt">
    <form method="post" action="">
        <textarea id="genes" cols="25" rows="5">Enter your genes here...</textarea><br>
        <input
                id="submitPE"
                class='txt'
                type="button"
                value="Run Enrichment"
                onclick="triggerPE()"/>
    </form>
</div>
<br/>

<hr class="myhr"/>
<div id="cacheTable">
    <table id="peTable">
        <tr>
            <td><b><i>Name</i></b></td>
            <td><b><i>Date</i></b></td>
            <td><b><i>Status</i></b></td>
        </tr>
    </table>
</div>

<script>
    function triggerPE() {
        runPE(document.getElementById("genes").value)
    }

    populateCacheDIV()

</script>



