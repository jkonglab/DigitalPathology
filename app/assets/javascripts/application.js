// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//

//= require jquery3
//= require jquery_ujs
//= require jquery-ui
//= require bootstrap-slider
//= require underscore/underscore
//= require bootstrap
//= require backbone/backbone
//= require backbone-forms
//= require backbone-forms/distribution/editors/list
//= require bootstrap-material-design/dist/js/material
//= require bootstrap-material-design/dist/js/ripples
//= require formstone/dist/js/core
//= require formstone/dist/js/upload
//= require_tree ../../../node_modules/openseadragon/build
//= require_tree ../../../node_modules/openseadragon-annotations/dist
//= require_tree .


$(function(){
	$("tr.image-link").click(function(e) {
		if(e.target.type != 'checkbox'){
			window.location = $(this).attr('data-link');
		}
	});
});