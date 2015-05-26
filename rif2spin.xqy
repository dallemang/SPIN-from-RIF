declare default element namespace  "http://www.w3.org/2007/rif#";
declare namespace saxon="http://saxon.sf.net/";
declare namespace xsd = "http://www.w3.org/2001/XMLSchema#";
declare option saxon:output "method=text";

declare variable $nl := "
";   (:   Newline :)
declare variable $q3 := """""""" ;  (: Triple quote (for quoting blocks) :)

declare function local:unframe ($f)
{ fn:string-join((
                  for $x in $f/object/(Var|Const) return local:parseatom($x) ,
		  for $x in $f/slot/(Var|Const) return local:parseatom($x),
		  ' .&#xa;' ), " ") };


declare function local:parsecall ($f as node())
{
  let $fun := data($f//content/Atom/op)
  let $args := for $x in $f//content/Atom/args/(Var|Const) return local:parseatom($x)
    (: Switch on supported functions here  :)
 
  return if ($fun = "NEQ") then fn:concat ("FILTER (", $args[1], " != ", $args[2], ")", " .&#xa;")   (: NEQ is not equal :)
  else if ($fun = "NEQ") then fn:concat ("FILTER (", $args[1], " = ", $args[2], ")", " .&#xa;")   (: EQ is equal :)
else ()                                                    (: That's all :)
};

declare function local:parseatom ($a as item())
{
  if (fn:name($a) = "Var") then fn:concat ("?", xs:string ($a))
  else if ($a/@type = "http://www.w3.org/2007/rif#iri") then fn:concat ("<", xs:string ($a), ">")
  else if (fn:matches (xs:string($a/@type), "http...www.w3.org.2001.XMLSchema", "i"))
  then fn:concat ("""", data($a), """^^xsd:", fn:substring-after(data($a/@type), "#"))
else ()
};


let $constraints := //sentence/Forall/formula/Implies/then/Atom/op[Const="http://www.w3.org/2007/rif#error"]/../../../../../..

let $rules := //sentence/Forall/formula/Implies/then/Frame/../../../../..

return (
"
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix sp: <http://spinrdf.org/sp#> .
@prefix spin: <http://spinrdf.org/spin#> .
@prefix spl: <http://spinrdf.org/spl#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
", 



"# Constraints" ,
 $nl, $nl,
if (empty ($constraints)) then () else ( "owl:Thing spin:constraint ",
fn:string-join (for $i in $constraints//Implies
let $where := string-join(( for $x in $i/if//Frame return local:unframe($x),
                            for $x in $i/if//formula/External return local:parsecall($x)
			  ), " ")  
return  

 fn:concat (
 " [ rdf:type sp:Ask ; sp:text ", $q3,    
   "&#xa;&#xa;ASK  &#xa;WHERE {", $where, "}&#xa;",
 $q3, "^^xsd:string  ] ", $nl ), ","),
".", $nl),


$nl,

"# Rules" ,
 $nl, $nl,
if (empty ($rules)) then () else ("owl:Thing spin:rule ",
fn:string-join (for $i in $rules//Implies
let $where := string-join( (
                            for $x in $i/if//Frame return local:unframe($x),
			    for $x in $i/if//formula/External return local:parsecall($x) )
			     , " ")  
let $construct := string-join(for $x in $i/then//Frame return  local:unframe($x), " ")
return  

 fn:concat (
 " [ rdf:type sp:Construct ; sp:text ", $q3, 
 "&#xa;&#xa;CONSTRUCT {", $construct, "} &#xa;WHERE {", $where, "}&#xa;",
 $q3, "^^xsd:string  ] ", $nl ), ","),
"."), $nl


,
"<http://example.org/BE.spin.ttl>
  rdf:type owl:Ontology ;
  owl:imports <http://spinrdf.org/spin> 
.
"

)
