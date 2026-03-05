function scrollDetection() {
	const scrollElement = document.scrollingElement || document.documentElement || document.body;
	if (!scrollElement) {
		return;
	}

	scrollElement.addEventListener("scroll", function() {
		window.webkit.messageHandlers.windowDidScroll.postMessage(scrollElement.scrollTop);
	}, { passive: true });
}

function linkHover() {
	window.onmouseover = function(event) {
		var closestAnchor = event.target.closest('a')
		if (closestAnchor) {
			window.webkit.messageHandlers.mouseDidEnter.postMessage(closestAnchor.href);
		}
	}
	window.onmouseout = function(event) {
		var closestAnchor = event.target.closest('a')
		if (closestAnchor) {
			window.webkit.messageHandlers.mouseDidExit.postMessage(closestAnchor.href);
		}
	}
}

function postRenderProcessing() {
	scrollDetection();
	linkHover();
}
