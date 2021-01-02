BEGIN {
       FS="->";
       print "<table>"
       print "<colgroup><col/><col/></colgroup>"
       print "<tr class=3D'even'>"
       print "  <th>DOMAIN</th>"
       print "  <th>EXPIRE DATE</th>"
       print "</tr>"
}
      { print "<tr class=3D'even'>";
          for(i=1;i<=NF;i++) print "<td class=3D'odd'>" $i"</td>";
        print "</tr>"}
END {
     print "</table>"
    }

