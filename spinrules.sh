#!/bin/bash
java -Xmx1024M -Dlog4j.configuration="file:$JENAROOT/jena-log4j.properties" -cp "$JENAROOT/lib/*;.;SPIN/spin-1.3.3.jar" org.topbraid.spin.tools.RunInferences "$1" "$2"
