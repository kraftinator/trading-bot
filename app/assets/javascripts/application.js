// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require popper
//= require bootstrap-sprockets
//= require turbolinks
//= require_tree .
	
	var dataTable;
	document.addEventListener("turbolinks:load", function() {
		if ($('.datatable-list').length) {
			dataTable = $('.datatable-list').DataTable( {
				"lengthMenu":[[-1, 25, 50, 100], ["All", 25, 50, 100]],
				"order":[]
			});
		} else if ($('.datatable-top-bots').length) {
			$.fn.DataTable.ext.pager.numbers_length = 5;
			dataTable = $('.datatable-top-bots').DataTable({
				"bLengthChange":false,
				"pageLength":5,
				"order":[[3, "desc"]],
				"columnDefs": [
					{ "orderSequence":["desc", "asc"], "targets":[3, 4] },
				]
			});
			$('.dataTables_wrapper').css("display", "none");
			$('.dataTables_wrapper:first').css("display", "inline");
			$('#timeSelector').change(function() {
				$('.dataTables_wrapper').css("display", "none");
				if (this.value == -1) {
					$('.dataTables_wrapper:first').css("display", "inline");
				} else {
					$('.dataTables_wrapper:first').nextAll().eq(this.value).css("display", "inline");
				}
			});
		}
	});
	
	document.addEventListener("turbolinks:before-cache", function() {
		if (dataTable !== null) {
			dataTable.destroy();
			dataTable = null;
		}	
	});
	
	document.addEventListener("turbolinks:load", function() {
		
	});
	
	document.addEventListener("turbolinks:load", function() {
	var ctx = document.getElementById("myChart");
	var coinName = [];
	var ethQuantity = [];
	var x = 0;
	$("td[id^='coin']").each( function() {
		coinName[x] = this.id.slice(4);
		x += 1;
	});
	x=0;
	$("td[id^='value']").each( function() {
		ethQuantity[x] = this.id.slice(5);
		x += 1;
	});
	var myChart = new Chart(ctx, {
	    type: 'pie',
	    data: {
	        labels: coinName,
	        datasets: [{
	            label: '',
	            data: ethQuantity,
	            backgroundColor: [
	                'rgba(255, 99, 132, 0.2)',
	                'rgba(54, 162, 235, 0.2)',
	                'rgba(255, 206, 86, 0.2)',
	                'rgba(75, 192, 192, 0.2)',
	                'rgba(153, 102, 255, 0.2)',
	                'rgba(255, 159, 64, 0.2)'
	            ],
	            borderColor: [
	                'rgba(255,99,132,1)',
	                'rgba(54, 162, 235, 1)',
	                'rgba(255, 206, 86, 1)',
	                'rgba(75, 192, 192, 1)',
	                'rgba(153, 102, 255, 1)',
	                'rgba(255, 159, 64, 1)'
	            ],
	            borderWidth: 1
	        }]
	    },
		options: {
			responsive: false,
			title: {
				display: true,
				text: 'Crypto Holdings'
			}
		}
	});
	});