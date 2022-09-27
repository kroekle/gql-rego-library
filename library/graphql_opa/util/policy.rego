package global.graphql_opa.util

import future.keywords.in

import data.schema

default graphql_document = {}

query_reference(type, field) {

 query_fields[type][field]
}

query_argument(reference, field, value) {
  query_arguments[_][reference][field] == value
}

mutate_reference(type, field) {

 mutation_fields[_][type][field]
}

mutate_argument(reference, field, value) {
  mutation_arguments[_][reference][field] == value
}

ast = a {
  not data.schema
  a := [graphql.parse_query(graphql_document)]
}

ast = a {
  a := graphql.parse(graphql_document, data.schema)
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

known_types[t] {
  inline_fragments[_][t]
}

known_types[t] {
  t := query_fields[_][_][_][_]
}

query_types[t] = properties {
    t := known_types[_]
    frag_props := {p | p := inline_fragments[_][t][_]}
    field_props := {p | 
      query_fields[i][j][_]["__type__"] = t
      query_fields[i][j][_][p]
      p != "__type__"}
    print(field_props)
    
    properties := {p:{}|  c := frag_props | field_props; p := c[_]}
}

inline_fragments[sub] {

  [_,node] = walk(ast[_].definitions)
  
  node.kind == "Field"
  
  sub := {type:names | 
    node.selectionSet.selections[i].kind == "InlineFragment"
    
    names := [n | n := node.selectionSet.selections[i].selectionSet.selections[_].name.value]
    type := node.selectionSet.selections[i].typeCondition.name.value
    }
}

query_arguments[v] {
  count(query_definitions[i].SelectionSet[j].Arguments) > 0
  name := query_definitions[i].SelectionSet[j].Name

  args := {field:value | 
    field := query_definitions[i].SelectionSet[j].Arguments[k].Name
    value := query_definitions[i].SelectionSet[j].Arguments[k].Value.Raw
    }
  v := {name: args} 
}

mutation_arguments[v] {
  count(mutation_definitions[i].SelectionSet[j].Arguments) > 0
  name := mutation_definitions[i].SelectionSet[j].Name

  args := {field:value | 
    field := mutation_definitions[i].SelectionSet[j].Arguments[k].Name
    value := mutation_definitions[i].SelectionSet[j].Arguments[k].Value.Raw
    }
  v := {name: args} 
}

query_definitions = d {
  ast
  d := [o | 
    ast[a].Operations[i].Operation in ["query", "subscription"]
    o = ast[a].Operations[i]
    ]
}

mutation_definitions = d {
  d := [d | 
    ast[a].Operations[i].Operation == "mutation"
    d := ast[a].Operations[i]
    ]
}

query_fields[v] {
  [_,node] = walk(query_definitions)

  sub := {{name:type} | 
    name := node.SelectionSet[i].Name
    type := get_type_from_definition(node.SelectionSet[i].Definition)
    }
  count(sub) > 0

  v := {node.Name: (sub | {{"__type__":get_type_from_definition(node.Definition)}})}
}

mutation_fields[v] {

  [_,node] = walk(mutation_definitions)

  sub := {{name:type} | 
    name := node.SelectionSet[i].Name
    type := get_type_from_definition(node.SelectionSet[i].Definition)
    }
  count(sub) > 0

  v := {node.Name: (sub | {{"__type__":get_type_from_definition(node.Definition)}})}
}

get_type_from_definition(definition) = t {
  t := definition.Type.Elem.NamedType
} else = t {
  t := definition.Type.NamedType
}
