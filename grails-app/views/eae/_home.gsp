
<head>
<g:javascript library='jquery' />
<g:javascript src='eae/eae.js' />
<g:javascript src="resource/d3.min.js"/>
<link href='http://fonts.googleapis.com/css?family=Roboto' rel='stylesheet' type='text/css'>
<link href='<g:resource dir="css" file="eae.css" />' rel='stylesheet' type='text/css'>
<r:layoutResources/>
    <style>
    .txt {
        font-family: 'Roboto', sans-serif;
    }
    </style>
</head>

<body>
    <div id="switch" style="text-align: right">
    <div id="index" style="text-align: center">
        <h1 class="txt"> Welcome to eTRIKS Analytical Engine.</h1><br/>

        <g:select
        name="hpcscriptSelect"
        class='txt'
        from="${hpcScriptList}"
        noSelection="['':'Choose an algorithm']"
        onchange="changeEAEInput()"/>
        <hr class="myhr"/>

        <div id="eaeinputs" class='txt' style="text-align: left">Please select a script to execute.</div>

    <hr class="myhr"/>
    </div>

    <div id="eaeoutputs" style="text-align: center"></div>
</body>

<script>


</script>