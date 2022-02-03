BEGIN {
  ORS=rs
}
{
  if ($0 ~ /[[:alnum:]]+ *{/) { 
    match($0,/^([[:alnum:]]+).*/,matches)
    name = matches[1]
    actions[name][0] = name
    idxcnt[name] = 1
  
  } else {
    if ($1 == "}"){
      next
    }
    if (NF == 1){
      action = "add"
      filename = $1
    }else{
      action = $1
      filename = $2
    }
    if (action != "") {
      idx= idxcnt[name]
      actions[name][idx] = action fs filename fs 0
      idxcnt[name] += 1
    }
  }

}
END {
  
  # Iterate through each record and print it
  for (name in idxcnt){
    len = length(actions[name])
    for (i=0; i < len; i++){
      print actions[name][i]
    }
  }
}
