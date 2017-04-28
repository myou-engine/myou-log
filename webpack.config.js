'use strict'

var webpack = require('webpack');
var path = require('path');

var raw_banner = ```
/*
* LICENSE (MIT):
*
* Copyright (c) 2016 by Julio Manuel López Tercero <julio@pixelements.net>
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

"use strict";
```

module.exports = {
    output: {
        path: __dirname + '/build',
        filename: 'app.js',
    },
    context: __dirname,
    entry: [
        __dirname + '/main.coffee',
    ],
    stats: {
        colors: true,
        reasons: true
    },
    module: {
        rules: [
            {
                test: /\.coffee$/,
                loaders: [
                    'coffee-loader',
                    'source-map-loader',
                ]
            },
            {
                test: /\.(png|jpe?g|gif)$/i,
                loader: 'url-loader?limit=18000&name=[path][name].[ext]',
            },
            {test: /\.svg$/, loader: 'url-loader?mimetype=image/svg+xml'},
            {test: /\.json$/, loader: 'json-loader'},
            {test: /\.html$/, loader: 'raw-loader'},
        ]
    },
    devtool: 'inline-source-map',
    plugins: [
        new webpack.BannerPlugin({banner:raw_banner, raw:true}),
        new webpack.IgnorePlugin(/^(fs|stylus|path|coffee-script)$/),
    ],
    resolve: {
        extensions: [".webpack.js", ".web.js", ".js", ".coffee", ".json"],
        alias: {
            // // You can use this to override some packages and use local versions
            'myoui': path.resolve(__dirname+'/../myoui/main.coffee'),
        },
    },
}
