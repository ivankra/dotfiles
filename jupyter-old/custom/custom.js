// Move filename box into menubar.
$('#save_widget').detach().appendTo('.navbar-collapse')
$('#header-container').hide();

// Go to Running cell shortcut
// https://stackoverflow.com/questions/44273643
Jupyter.keyboard_manager.command_shortcuts.add_shortcut('Alt-I', {
    help : 'Go to Running cell',
    help_index : 'zz',
    handler : function (event) {
        setTimeout(function() {
            // Find running cell and click the first one
            if ($('.running').length > 0) {
                $('.running')[0].scrollIntoView();
            }}, 250);
        return false;
    }
});
