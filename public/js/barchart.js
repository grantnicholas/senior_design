google.load("visualization", '1', {packages:['corechart']});
google.setOnLoadCallback(drawChart);
function drawChart() {

  var data = google.visualization.arrayToDataTable([
    ['Element', 'Density', { role: 'style' }],
    ['Copper', 8.94, '#b87333', ],
    ['Silver', 10.49, 'silver'],
    ['Gold', 19.30, 'gold'],
    ['Platinum', 21.45, 'color: #e5e4e2' ]
  ]);

  var options = {
    title: "Density of Precious Metals, in g/cm^3",
    bar: {groupWidth: '95%'},
    legend: 'none',
  };

  var chart_div = document.getElementById('chart_div');
  var chart = new google.visualization.ColumnChart(chart_div);

  // Wait for the chart to finish drawing before calling the getImageURI() method.
  google.visualization.events.addListener(chart, 'ready', function () {
    chart_div.innerHTML = '<img src="' + chart.getImageURI() + '">';
    console.log(chart_div.innerHTML);
  });

  chart.draw(data, options);
  document.getElementById('png').outerHTML = '<a href="' + chart.getImageURI() + '>Printable version</a>';
}