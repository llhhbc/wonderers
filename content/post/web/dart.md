
+++
title = "dart use"
description = "dart use"
tags = [
    "dart",
    "js",
    "d3"
]
date = "2018-08-12T20:01:00+08:00"
categories = [
    "dart",
]
+++


#### dart use d3.js

```js
import 'dart:html';
import 'package:js/js.dart' as js;

void main() {
  var dee3 = js.context.d3; 
  var dataset = js.array([ 5, 10, 15, 20, 25 ]);
  dee3.select("body").selectAll("p")
    .data(dataset)
    .enter()
    .append("p")
    .text((d, i, context) => d);
}
```

