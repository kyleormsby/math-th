<?xml version="1.0" encoding="UTF-8"?>

<!-- Custom HTML stylesheet for Math Trailhead.                               -->
<!--                                                                          -->
<!-- Purpose: activate WeBWorK problems without the reader clicking the        -->
<!-- "Activate" button on each one.                                            -->
<!--                                                                          -->
<!-- PreTeXt has no publication-file option for this; the button is emitted    -->
<!-- unconditionally for every dynamic WeBWorK exercise. So we override the    -->
<!-- "extra-js-footer" named template, which core calls at the end of the body -->
<!-- of every content page, and inject a script that clicks the buttons for    -->
<!-- us.                                                                       -->
<!--                                                                          -->
<!-- Problems activate as they scroll into view (600px ahead, so they are      -->
<!-- ready before the reader gets there). Pages here carry a median of 20      -->
<!-- problems and up to 28, and every activation is a request to the WeBWorK   -->
<!-- server. Firing all of them at once on every page view is a lot to ask of  -->
<!-- a server we do not run.                                                   -->
<!--                                                                          -->
<!-- THE FOCUS PROBLEM. PreTeXt's handleWW() moves keyboard focus to the       -->
<!-- problem being activated: once to a "Loading" overlay, synchronously       -->
<!-- during the click, and again to the problem container when the render      -->
<!-- finishes. That is correct behaviour for a reader who clicked the button,  -->
<!-- and wrong for a click we issued on their behalf: the browser scrolls to   -->
<!-- whatever just took focus, so activating problems below the fold yanks the -->
<!-- viewport down the page.                                                   -->
<!--                                                                          -->
<!-- The fix keeps the focus move and suppresses only the scrolling, by way of -->
<!-- focus({preventScroll: true}). The synchronous overlay focus is caught by  -->
<!-- swapping the prototype method for the duration of the click; the later    -->
<!-- asynchronous one is caught by overriding focus on that one container.      -->
<!--                                                                          -->
<!-- Failure modes are gentle: if this stops working after a PreTeXt upgrade   -->
<!-- (say the core template gets renamed), the buttons simply come back.       -->
<!--                                                                          -->
<!-- Wired up by xsl="custom-html.xsl" on the course target in project.ptx.    -->
<!-- The JavaScript below deliberately avoids the characters less-than,        -->
<!-- greater-than and ampersand, so it needs no XML escaping.                  -->

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:import href="./core/pretext-html.xsl"/>

<xsl:template name="extra-js-footer">
    <script>
        <xsl:text>
(function () {
    "use strict";

    var nativeFocus = HTMLElement.prototype.focus;

    function focusWithoutScrolling() {
        nativeFocus.call(this, { preventScroll: true });
    }

    function activate(button) {
        if (button.dataset.ptxAutoActivated) { return; }
        button.dataset.ptxAutoActivated = "1";

        // handleWW() focuses the problem container once the render returns,
        // long after this function has finished. Neutralize the scroll for
        // this container permanently: focus still lands there, it just stops
        // hauling the viewport along with it.
        var container = button.closest("div[data-domain]");
        if (container) {
            container.focus = focusWithoutScrolling;
        }

        // handleWW() also focuses a "Loading" overlay it builds on the fly,
        // synchronously inside the click. There is no element to patch ahead
        // of time, so swap the prototype method for the duration of the call.
        // Nothing else can run in between: click() is synchronous.
        HTMLElement.prototype.focus = focusWithoutScrolling;
        try {
            button.click();
        } finally {
            HTMLElement.prototype.focus = nativeFocus;
        }
    }

    function start() {
        var buttons = document.querySelectorAll("div.problem-buttons button.webwork-button");
        if (buttons.length === 0) { return; }

        if (typeof IntersectionObserver === "undefined") {
            buttons.forEach(activate);
            return;
        }

        var observer = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
                if (entry.isIntersecting) {
                    observer.unobserve(entry.target);
                    activate(entry.target);
                }
            });
        }, { rootMargin: "600px 0px" });

        buttons.forEach(function (button) { observer.observe(button); });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", start);
    } else {
        start();
    }
}());
        </xsl:text>
    </script>
</xsl:template>

</xsl:stylesheet>
