$(document).ready(function() {
    if (Cookies.get('cookie_notice') === '1') {
        $("#cookie_banner").hide()
    } else {
        $("#cookie_banner").show()
    }
    $( "#acceptcookie" ).click(function() {
        Cookies.set('cookie_notice', '1')
        $("#cookie_banner").hide()
    });
});