/**
 * Internal function used to dispatch the request to PhoneGap.  It processes the
 * command queue and executes the next command on the list.  If one of the
 * arguments is a JavaScript object, it will be passed on the QueryString of the
 * url, which will be turned into a dictionary on the other end.
 * @private
 */
PhoneGap.run_command = function() {
    if (!PhoneGap.available)
        return;

    PhoneGap.queue.ready = false;

    var args = PhoneGap.queue.commands.shift();
    if (PhoneGap.queue.commands.length == 0) {
        clearInterval(PhoneGap.queue.timer);
        PhoneGap.queue.timer = null;
    }

    var uri = [];
    var dict = null;
    for (var i = 1; i < args.length; i++) {
        if (typeof(args[i]) == 'object')
            dict = args[i];
        else
            uri.push(encodeURIComponent(args[i]));
    }
    var url = "gap://" + args[0] + "/" + uri.join("/");
    if (dict != null) {
        var query_args = [];
        for (var name in dict) {
            if (typeof(name) != 'string')
                continue;
            query_args.push(encodeURIComponent(name) + "=" + encodeURIComponent(dict[name]));
        }
        if (query_args.length > 0)
            url += "?" + query_args.join("&");
    }
    document.location = url;

};
