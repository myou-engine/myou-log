
// myou-log.js is the packed project when the index.html is loaded from the browser.
var file_path = function(module, filename) {
  module.exports = 'file://' + filename.replace(/\\/g, '/');
};
for(var ext of ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.woff']){
    require.extensions[ext] = file_path;
};
require('coffee-script/register');
var helpers = require('coffee-script').helpers, use = helpers.updateSyntaxError;
helpers.updateSyntaxError = function(e,c,f){
    return use(e, c, f).toString();
}
require('../src/main.coffee');
