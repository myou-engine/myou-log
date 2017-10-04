
var file_path = function(module, filename) {
  module.exports = 'file://' + filename.replace(/\\/g, '/');
};
for(var ext of ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.woff']){
    require.extensions[ext] = file_path;
};
require('coffeescript/register');
var helpers = require('coffeescript').helpers, use = helpers.updateSyntaxError;
helpers.updateSyntaxError = function(e,c,f){
    return use(e, c, f).toString();
}
