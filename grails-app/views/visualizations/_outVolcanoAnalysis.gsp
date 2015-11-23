<!DOCTYPE html>
<style>
.text {
    font-family: 'Roboto', sans-serif;
    fill: black;
}

.point {

}

.axis path,
.axis line {
    fill: none;
    stroke: black;
    shape-rendering: crispEdges;
}

.tooltip {
    position: absolute;
    text-align: center;
    display: inline-block;
    padding: 0px;
    font-size: 12px;
    font-weight: bold;
    color: #FFFFFF;
    background: #123456;
    pointer-events: none;
}

.square {

}

.pLine {
    stroke: red;
    stroke-width: 3px;
    shape-rendering: crispEdges;
}

.pLine:hover {
    opacity: 0.4;
    cursor: ns-resize;
}

.logFCLine {
    stroke: #0000FF;
    stroke-width: 2px;
    shape-rendering: crispEdges;
}

.axisText {
    font-size: 14px;
}

.brush .extent {
    fill: blue;
    opacity: .25;
    shape-rendering: crispEdges;
}

.mytable, .myth, .mytd {
    border: 1px solid black;
    border-collapse: collapse;
}

.myth, .mytd {
    padding: 5px;
}
</style>

<link href='http://fonts.googleapis.com/css?family=Roboto' rel='stylesheet' type='text/css'>
<g:javascript src="resource/d3.js"/>

<div id="visualization">
    <div id="volcanocontrols" style='float: left; padding-right: 10px'></div>
    <div id="volcanoplot" style='float: left; padding-right: 10px'></div><br/>
    <div id="volcanotable" style='float: left; padding-right: 10px'></div>
</div>

<script>
    d3.selection.prototype.moveToFront = function() {
        return this.each(function(){
            this.parentNode.appendChild(this);
        });
    };
    var animationDuration = 500;
    var tmpAnimationDuration = animationDuration;
    function switchAnimation(checked) {
        if (! checked) {
            tmpAnimationDuration = animationDuration;
            animationDuration = 0;
        } else {
            animationDuration = tmpAnimationDuration;
        }
    }

    var results = ${results};
    var uids = results.uids;
    var pValues = results.pValues;
    var negativeLog10PValues = results.negativeLog10PValues;
    var logFCs = results.logFCs;
    var patientIDs = results.patientIDs;
    var zScoreMatrix = results.zScoreMatrix;

    var points = jQuery.map(negativeLog10PValues, function(d, i) {
        return {uid: uids[i],
            pValue: pValues[i],
            negativeLog10PValues: negativeLog10PValues[i],
            logFC: logFCs[i]
        };
    });

    var margin = {top: 100, right: 100, bottom: 100, left: 100};
    var width = 1200 - margin.left - margin.right;
    var height = 800 - margin.top - margin.bottom;

    var oo5p = - Math.log10(0.05);

    var volcanotable = d3.select("#volcanotable").append("table")
            .attr("width", width)
            .attr("height", height);

    var volcanoplot = d3.select("#volcanoplot").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var controls = d3.select("#volcanocontrols").append("svg")
            .attr("width", 220)
            .attr("height", height * 2);

    var x = d3.scale.linear()
            .domain(d3.extent(logFCs))
            .range([0, width]);

    var y = d3.scale.linear()
            .domain(d3.extent(negativeLog10PValues))
            .range([height, 0]);

    var xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom");

    var yAxis = d3.svg.axis()
            .scale(y)
            .orient("left");

    volcanoplot.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);

    volcanoplot.append("g")
            .attr("class", "axis")
            .call(yAxis);

    volcanoplot.append('text')
            .attr('class', 'text axisText')
            .attr('x', width / 2)
            .attr('y', height + 40)
            .attr('text-anchor', 'middle')
            .text('log2 FC');

    volcanoplot.append('text')
            .attr('class', 'text axisText')
            .attr('text-anchor', 'middle')
            .attr("transform", "translate(" + (-40) + "," + (height / 2) + ")rotate(-90)")
            .text('- log10 p');

    var tooltip = d3.select('#volcanoplot').append("div")
            .attr("class", "tooltip text")
            .style("visibility", "hidden");

    var brush = d3.svg.brush()
            .x(d3.scale.identity().domain([-20, width + 20]))
            .y(d3.scale.identity().domain([-20, height + 20]))
            .on("brushend", function() {
                updateSelection();
            });

    volcanoplot.append("g")
            .attr("class", "brush")
            .on("mousedown", function(){
                if(d3.event.button === 2){
                    d3.event.stopImmediatePropagation();
                }
            })
            .call(brush);

    function pDragged() {
        var yPos = d3.event.y;
        if (yPos < 0 ) {
            yPos = 0;
        }
        if (yPos > height) {
            yPos = height;
        }
        d3.selectAll('.pLine')
                .attr("y1", yPos)
                .attr("y2", yPos);
        d3.selectAll('.pText')
                .attr('y', yPos)
                .text((1 / Math.pow(10, y.invert(yPos))).toFixed(5));
    }

    var pDrag = d3.behavior.drag()
            .on("drag", pDragged);

    volcanoplot.append('line')
            .attr('class', 'pLine')
            .attr('x1', 0)
            .attr('y1', y(oo5p))
            .attr('x2', width)
            .attr('y2', y(oo5p))
            .call(pDrag);

    volcanoplot.append('text')
            .attr('class', 'text pText')
            .attr('x', width + 5)
            .attr('y', y(oo5p))
            .attr('dy', '0.35em')
            .attr("text-anchor", "start")
            .text('p = 0.0500')
            .style('fill', 'red');

    volcanoplot.append('line')
            .attr('class', 'left logFCLine')
            .attr('x1', x(-0.5))
            .attr('y1', height)
            .attr('x2', x(-0.5))
            .attr('y2', 0);

    volcanoplot.append('line')
            .attr('class', 'right logFCLine')
            .attr('x1', x(0.5))
            .attr('y1', height)
            .attr('x2', x(0.5))
            .attr('y2', 0);

    volcanoplot.append('text')
            .attr('class', 'text left logFCText')
            .attr('x', x(-0.5))
            .attr('y', - 15)
            .attr('dy', '0.35em')
            .attr("text-anchor", "middle")
            .text('log2FC = -0.5')
            .style('fill', '#0000FF');

    volcanoplot.append('text')
            .attr('class', 'text right logFCText')
            .attr('x', x(0.5))
            .attr('y', - 15)
            .attr('dy', '0.35em')
            .attr("text-anchor", "middle")
            .text('log2FC = 0.5')
            .style('fill', '#0000FF');

    function updateSelection() {
        var selection = [];
        d3.selectAll('.point')
                .classed('brushed', false);

        var extent = brush.extent();
        var left = extent[0][0],
                top = extent[0][1],
                right = extent[1][0],
                bottom = extent[1][1];

        d3.selectAll('.point').each(function(d) {
            var point = d3.select(this);
            if (y(d.negativeLog10PValues) >= top && y(d.negativeLog10PValues) <= bottom && x(d.logFC) >= left && x(d.logFC) <= right) {
                point
                        .classed('brushed', true);
                selection.push(d);
            }
        });
        drawVolcanotable(selection);
    }

    var absLogFCs = jQuery.map(logFCs, function(d) { return Math.abs(d); });
    var negativeLog10PValuesMinMax = d3.extent(negativeLog10PValues);
    var logFCsMinMax = d3.extent(absLogFCs);

    function redGreen() {
        var colorSet = [];
        var NUM = 100;
        var i = NUM;
        while(i--) {
            colorSet.push(d3.rgb((255 * i) / NUM, 0, 0));
        }
        i = NUM;
        while(i--) {
            colorSet.push(d3.rgb(0, (255 * (NUM - i)) / NUM, 0));
        }
        return colorSet;
    }

    var colorScale = d3.scale.quantile()
            .domain([0, 1])
            .range(redGreen());

    function getColor(point) {
        if (point.negativeLog10PValues < oo5p && Math.abs(point.logFC) < 0.5) {
            return '#000000';
        }
        if (point.negativeLog10PValues >= oo5p && Math.abs(point.logFC) < 0.5) {
            return '#FF0000';
        }
        if (point.negativeLog10PValues >= oo5p && Math.abs(point.logFC) >= 0.5) {
            return '#00FF00';
        }
        return '#0000FF';
    }

    function resetVolcanotable() {
        d3.select('#volcanotable').selectAll('*').remove();
    }

    function drawVolcanotable(points) {
        resetVolcanotable();
        if (!points.length) {
            return;
        }
        var columns = ["uid", "logFC", "negativeLog10PValues", 'pValue'];
        var HEADER = ["ID", "log2 FC", "- log10 p", "p"];
        var table = d3.select('#volcanotable').append("table")
                .attr('class', 'mytable');
        var thead = table.append("thead");
        var tbody = table.append("tbody");

        thead.append("tr")
                .attr('class', 'mytr')
                .selectAll("th")
                .data(HEADER)
                .enter()
                .append("th")
                .attr('class', 'myth')
                .text(function(d) { return d; });

        var rows = tbody.selectAll("tr")
                .data(points)
                .enter()
                .append("tr")
                .attr('class', 'mytr');

        var cells = rows.selectAll("td")
                .data(function(row) {
                    return columns.map(function(column) {
                        return {column: column, value: row[column]};
                    });
                })
                .enter()
                .append("td")
                .attr('class', 'text mytd')
                .text(function(d) { return d.value; });
    }

    function launchKEGGPWEA(geneList) {
        jQuery.ajax({
            url: 'http://biocompendium.embl.de/cgi-bin/biocompendium.cgi',
            type: "POST",
            timeout: '10000',
            async: false,
            data: {
                section: 'upload_gene_lists_general',
                primary_org: 'human',
                background: 'whole_genome',
                Category1: 'human',
                gene_list_1: 'gene_list_1',
                SubCat1: 'hgnc_symbol',
                attachment1: geneList
            }
        }).done(function(response) {
            var sessionID = response.match(/tmp_\d+/)[0];
            var url = "http://biocompendium.embl.de/cgi-bin/biocompendium.cgi?section=pathway&pos=0&background=whole_genome&session=" + sessionID + "&list=gene_list_1__1&list_size=15&org=human";
            window.open(url);
        }).fail(function() {
            alert('An error occured. Maybe the external resource is unavailable.');
        });
    }

    function updateVolcano() {
        var point = volcanoplot.selectAll(".point")
                .data(points, function(d) { return d.uid; });

        point.enter()
                .append("rect")
                .attr("class", function(d) { return "point uid-" + d.uid; })
                .attr("x", function(d) { return x(d.logFC) - 2; })
                .attr("y", function(d) { return y(d.negativeLog10PValues) - 2; })
                .attr("width", 4)
                .attr("height", 4)
                .style("fill", function(d) { return getColor(d); })
                .on("mouseover", function(d) {
                    var html = "p-value:" + d.pValue + "<br/>" + "-log10 p: " + d.negativeLog10PValues + "<br/>" + "log2FC: " + d.logFC + "<br/>" + "ID: " + d.uid;
                    tooltip.html(html)
                            .style("visibility", "visible")
                            .style("left", mouseX() + 10 + "px")
                            .style("top", mouseY() + 10 + "px");
                })
                .on("mouseout", function(d) {
                    tooltip.style("visibility", "hidden");
                });

        point.exit()
                .transition()
                .duration(animationDuration)
                .attr("r", 0)
                .remove();
    }

    updateVolcano();

    var buttonWidth = 200;
    var buttonHeight = 40;
    var padding = 5;

    createD3Switch({
        location: controls,
        onlabel: 'Animation ON',
        offlabel: 'Animation OFF',
        x: 2,
        y: 2 + padding * 0 + buttonHeight * 0,
        width: buttonWidth,
        height: buttonHeight,
        callback: switchAnimation,
        checked: true
    });


    var keggButton = createD3Button({
        location: controls,
        label: 'Find KEGG Pathway',
        x: 2,
        y: 2 + padding * 1 + buttonHeight * 1,
        width: buttonWidth,
        height: buttonHeight,
        callback: launchKEGGPWEA
    });
</script>
