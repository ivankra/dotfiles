define([
  'base/js/namespace',
  'base/js/promises'
], function(Jupyter, promises) {
  promises.app_initialized.then(function(appname) {
    if (appname === 'NotebookApp') {
      //cell.options_default.cm_config.indentUnit = 2;
    }
  });
});
