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
<!-- Rather than firing every problem at page load, problems activate as they  -->
<!-- scroll into view (600px ahead, so they are ready before the reader gets   -->
<!-- there). Pages here carry a median of 20 problems and up to 28, and every  -->
<!-- activation is a request to the WeBWorK server. Firing all of them at once -->
<!-- on every page view is a lot to ask of a server we do not run.             -->
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

    function activate(button) {
        if (button.dataset.ptxAutoActivated) { return; }
        button.dataset.ptxAutoActivated = "1";
        button.click();
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
