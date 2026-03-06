// ai_inject.js
// NetNewsWire
//
// JavaScript functions for AI translation and summary DOM injection.
// All functions prefixed with "nnw" to avoid name collisions.

// --- Translation ---

var nnwOriginalBody = null;
var nnwOriginalTitle = null;

function nnwShowTranslation(translatedTitle, translatedBody) {
	var bodyContainer = document.getElementById('bodyContainer');
	var titleEl = document.querySelector('.articleTitle h1 a');

	if (bodyContainer) {
		if (!nnwOriginalBody) {
			nnwOriginalBody = bodyContainer.innerHTML;
		}
		bodyContainer.innerHTML = translatedBody;
	}

	if (titleEl && translatedTitle && translatedTitle.length > 0) {
		if (!nnwOriginalTitle) {
			nnwOriginalTitle = titleEl.innerHTML;
		}
		titleEl.innerHTML = translatedTitle;
	}
}

function nnwRevertTranslation() {
	if (nnwOriginalBody) {
		var bodyContainer = document.getElementById('bodyContainer');
		if (bodyContainer) {
			bodyContainer.innerHTML = nnwOriginalBody;
		}
		nnwOriginalBody = null;
	}

	if (nnwOriginalTitle) {
		var titleEl = document.querySelector('.articleTitle h1 a');
		if (titleEl) {
			titleEl.innerHTML = nnwOriginalTitle;
		}
		nnwOriginalTitle = null;
	}
}

function nnwIsTranslated() {
	return nnwOriginalBody !== null;
}

// --- Summary ---

function nnwShowSummary(summaryHTML) {
	nnwRemoveSummary();

	var container = document.createElement('div');
	container.id = 'nnw-ai-summary';
	container.style.cssText =
		'margin: 12px 0 20px 0;';
	container.innerHTML =
		'<div style="' +
		'background: rgba(128,128,128,0.08);' +
		'border-left: 4px solid rgba(0,122,255,0.7);' +
		'border-radius: 6px;' +
		'padding: 12px 16px;' +
		'font-size: 0.92em;' +
		'line-height: 1.6;' +
		'">' +
		'<div style="font-weight:600; margin-bottom:8px; opacity:0.7; font-size:0.85em; text-transform:uppercase; letter-spacing:0.5px;">Summary</div>' +
		summaryHTML +
		'<div style="text-align:right; margin-top:8px;">' +
		'<a href="javascript:void(0)" onclick="nnwRemoveSummary()" ' +
		'style="font-size:0.82em; opacity:0.5; text-decoration:none;">Dismiss</a></div>' +
		'</div>';

	var bodyContainer = document.getElementById('bodyContainer');
	if (bodyContainer) {
		bodyContainer.insertBefore(container, bodyContainer.firstChild);
	}
}

function nnwRemoveSummary() {
	var existing = document.getElementById('nnw-ai-summary');
	if (existing) {
		existing.remove();
	}
}

// --- Loading State ---

function nnwShowAILoading(type) {
	nnwRemoveAILoading(type);

	var container = document.createElement('div');
	container.id = 'nnw-ai-loading-' + type;
	container.style.cssText =
		'text-align: center; padding: 20px; opacity: 0.5; font-size: 0.9em;';

	var label = (type === 'translate') ? 'Translating' : 'Summarizing';
	container.innerHTML =
		'<div style="display:inline-block;">' +
		'<span class="nnw-ai-spinner"></span> ' + label + '...' +
		'</div>' +
		'<style>' +
		'.nnw-ai-spinner {' +
		'  display: inline-block; width: 14px; height: 14px;' +
		'  border: 2px solid rgba(128,128,128,0.3);' +
		'  border-top-color: rgba(128,128,128,0.8);' +
		'  border-radius: 50%;' +
		'  animation: nnwSpin 0.8s linear infinite;' +
		'  vertical-align: middle; margin-right: 6px;' +
		'}' +
		'@keyframes nnwSpin { to { transform: rotate(360deg); } }' +
		'</style>';

	var bodyContainer = document.getElementById('bodyContainer');
	if (bodyContainer) {
		bodyContainer.insertBefore(container, bodyContainer.firstChild);
	}
}

function nnwRemoveAILoading(type) {
	var el = document.getElementById('nnw-ai-loading-' + type);
	if (el) {
		el.remove();
	}
}
