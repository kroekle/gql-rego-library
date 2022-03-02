package global.graphql

import data.schema

default graphql_document = {}

default ast_url = "http://localhost:3333"


query_reference(type, field) {

 query_fields[_][type][field]
}

query_argument(reference, field, value) {
  query_arguments[_][reference][field] == value
}

mutate_type(type, field) {

 mutation_fields[i][refernece][field]
 mutation_fields[i][reference][__type__] == type
}

mutate_reference(type, field) {

 mutation_fields[_][type][field]
}

mutate_argument(reference, field, value) {
  mutation_arguments[_][reference][field] == value
}


ast_url = u {
  u := data.policy["com.styra.envoy.ingress"].rules.rules.ast_url
}

body = b {
  not graphql_variables
  b := {"query": graphql_document}
}

body = b {
  b := {"query": graphql_document, "variables": graphql_variables}
}

ast = a {
  req := {
    "url": ast_url,
    "method": "POST",
    "body": body,
    "cache": true,
    "headers": {"content-type":"application/json"}
  }
  res := http.send(req)
  a := res.body
}

graphql_variables = v {
  v := input.attributes.request.http.headers.variables
}

graphql_variables = v {
  v := input.parsed_query.variables
}

graphql_variables = v {
  v := input.parsed_body.variables
}

graphql_document = g {
  g := input.parsed_body.query
} 

graphql_document = g {
  not input.parsed_body.query
  g := input.attributes.request.http.body
}

graphql_document = g {
  g := input.parsed_query.query
}

schema_types = schema_interfaces | schema_objects

schema_interfaces[i] {
  [_,node] = walk(schema.definitions)
  node.kind == "InterfaceTypeDefinition"
  
  fs := {name:{"type":type, "kind": kind} | 
    node.fields[i].kind == "FieldDefinition"
    name := node.fields[i].name.value
    type := node.fields[i].type.type.name.value
    kind := node.fields[i].type.kind
    
    }
    
    i := {node.name.value: fs}
}

schema_objects[o] {
  [_,node] = walk(schema.definitions)
  node.kind == "ObjectTypeDefinition"
  
  fs := {name:{"type":type, "kind": kind} | 
    node.fields[i].kind == "FieldDefinition"
    name := node.fields[i].name.value
    type := node.fields[i].type.type.name.value
    kind := node.fields[i].type.kind
    
    }
    
    o := {node.name.value: fs}
}

schema_fields[v] {
#non list types
  [_,node] = walk(schema.definitions)
  node.kind == "FieldDefinition"
  

   v := {
     node.name.value: {
       "type": node.type.name.value
     }}
}

schema_fields[v] {
#list types
  [_,node] = walk(schema.definitions)
  node.kind == "FieldDefinition"
  
   v := {
     node.name.value: {
       "type": node.type.type.name.value
     }}
}


known_types[t] {
  inline_fragments[_][t]
}

known_types[t] {
  t := query_fields[_][_]["__type__"]
}

query_types[t] = properties {
    t := known_types[_]
    frag_props := {p | p := inline_fragments[_][t][_]}
    field_props := {p | query_fields[_][p]["__type__"] = t}
    print(field_props)
    
    properties := {p:{}|  c := frag_props | field_props; p := c[_]}
}

inline_fragments[sub] {

  [_,node] = walk(ast.definitions)
  
  node.kind == "Field"
  
  sub := {type:names | 
    node.selectionSet.selections[i].kind == "InlineFragment"
    
    names := [n | n := node.selectionSet.selections[i].selectionSet.selections[_].name.value]
    type := node.selectionSet.selections[i].typeCondition.name.value
    }
}

query_arguments[v] {
  [_,q_node] = walk(ast.definitions)
  q_node.operation == ["query", "subscription"][_]

  [_,node] = walk(q_node)
  count(node.arguments) > 0
  args := {field:value | 
    node.arguments[i].kind == "Argument"
    value := node.arguments[j].value.value
    field := node.arguments[j].name.value
    # TODO: do not ignore value.kind
    }
  v := {node.name.value: args} 
}

mutation_arguments[v] {
  [_,node] = walk(ast.definitions)
  node.name.kind == "Name"
  node.operation == "mutation"
  count(node.arguments) > 0
  args := {field:value | 
    node.arguments[i].kind == "Argument"
    value := node.arguments[j].value.value
    field := node.arguments[j].name.value
    # TODO: do not ignore value.kind
    }
  v := {node.name.value: args} 
}

query_definitions = d {
  d := [d | 
    ast.definitions[i].kind == "OperationDefinition"
    ast.definitions[i].operation == ["query", "subscription"][_]
    d := ast.definitions[i]
    ]
}

mutation_definitions = d {
  d := [d | 
    ast.definitions[i].kind == "OperationDefinition"
    ast.definitions[i].operation == "mutation"
    d := ast.definitions[i]
    ]
}

query_fields[v] {

  [_,node] = walk(query_definitions)
  node.kind == "Field"
  node.name.kind == "Name"
  
  sub := {name:{"__type__":get_type(node.name.value, name)} | 
    node.selectionSet.selections[i].kind == "Field"
    node.selectionSet.selections[i].name.kind == "Name"
    name := node.selectionSet.selections[i].name.value
    }
  count(sub) > 0

  x := json.patch(sub,  [
    {"op": "add", "path": "/__type__", "value": get_type(node.name.value, "")}
    ])
  v := {node.name.value: x}
}

mutation_fields[v] {

  [_,node] = walk(mutation_definitions)
  node.kind == "Field"
  node.name.kind == "Name"

  sub := {name:{"__type__":get_type(node.name.value, name)} | 
    node.selectionSet.selections[i].kind == "Field"
    node.selectionSet.selections[i].name.kind == "Name"
    name := node.selectionSet.selections[i].name.value
    }
  count(sub) > 0

  x := json.patch(sub,  [
    {"op": "add", "path": "/__type__", "value": get_type(node.name.value, "")}
    ])
  v := {node.name.value: x}
}

get_type(object, field) = t {
  f := schema_fields[_][object]
  t := schema_types[_][f.type][field].type
} else = t {
  t := schema_fields[_][object].type
}
