/*
 * --------------------------------------------
 * Sugar
 *
 * @since 7.8.0
 * 
 * Copyright:: Copyright 2015 杨晨晨.
 *
 * --------------------------------------------
 */

var RBC = {
    debug: false,
    isSu: /SketchUp/i.test(navigator.userAgent),
    isWin: navigator.appVersion.indexOf("Win") !== -1,
    isMac: navigator.appVersion.indexOf("Mac") !== -1,
    isSafari: navigator.userAgent.indexOf("Safari") > -1 && navigator.userAgent.indexOf("Chrome") === -1,
    isChrome: navigator.userAgent.indexOf('Chrome') > -1,

    /**
     * Hash function to get short and reproducible identifiers.
     * @param {object} object
     */
    hashValue: function (s, l) {
        var s = String(s),
            h = 0,
            m = 99999,
            c;
        for (var i = 0; i < s.length; i++) {
            c = s.charCodeAt(i);
            h = (128 * h + c) % m;
        }
        return h;
    }

};

/*
* gui module.
*
* @submodule RBC.GUI
*
* */
RBC.GUI = {};

/*
*
* */
RBC.GUI.HtmlDialog = {

    name: 'RBC.GUI.HtmlDialog',

    /*
     * close dialog.
     *
     * @method: close
     *
     * */
    close: function () {
        this.callback('_close', true)
    },

    /*
    *
    * */
    ready: function (data, success) {
        window.setTimeout(function () {
            RBC.GUI.HtmlDialog.callback({
                name: 'ready',
                data: data,
                success: success
            });
        }, 50);
    },

    /* Wrapper to call any defined action_callback, handles escaping and encoding etc.
     * @param json
     * {
     *    name: string,
     *    data: json,
     *    test: function,
     *    success: function,
     *    error: function,
     *    complete: function
     * }
     * @param name, *arguments
     */
    callback: function () {
        // merge the given arguments with
        var opt = {
                success: function () {
                }, // null,
                error: function () {
                }, // null,
                complete: function () {
                }  // null
            },
            name = null,
            args = [];
        if (arguments.length === 1 && typeof(arguments[0]) === 'object') {
            json = arguments[0];
            for (var key in json) {
                opt[key] = json[key]
            }
            name = opt.name;
            args = opt.data;
            if (!RBC.isSu) {
                if (typeof(opt.test) !== 'undefined') {
                    try {
                        value = opt.test(args);
                    } catch (e) {
                        alert(e);
                        opt.error(e)
                    }
                    opt.success(value);
                    opt.complete(value);
                    return true;
                } else {
                    if (window.console !== undefined) {
                        console.log('Error(J): Please add the Test function key!');
                    }
                    return false;
                }
            }
        } else if (arguments.length >= 1) {
            name = arguments[0];
            args = Array.prototype.slice.call(arguments).slice(1)[0];
            if (!RBC.isSu) {
                if (window.console !== undefined) {
                    console.log('Error(J): Please execute it in SU!');
                }
                return false
            }
        } else if (arguments.length === 1 && typeof(arguments[0]) === "string") {
            name = arguments[0];
            args = null;
            if (!RBC.isSu) {
                if (window.console !== undefined) {
                    console.log('Error(J): Please execute it in SU!');
                }
                return false
            }
        } else {
            if (window.console !== undefined) {
                console.log('Error(J): Incorrect parameter!');
            }
            return false
        }
        var id = (this._messageIdCounter++);
        this._callbacks[id] = opt;
        this._messages.push({
            'fromFrame': 'HtmlDialog',
            'name': name,
            'id': id,
            'data': args
        });
        if (this._ready) {
            this._nextMessage()
        }
    },

    _nextMessage: function () {
        var message = this._messages.shift();
        if (!message) {
            this._ready = true;
            return;
        }
        this._ready = false;
        var js_command = 'sketchup.' + message.name + '(' + JSON.stringify(message) + ')';
        try {
            setTimeout(function () {
                eval(js_command);
            }, 0);
        } catch (e) {
            alert('ERROR(J): An exception occurred with the JS method:(sketchup.action);ActionName:(' + message[0] + ')' + e.toString());
        }
    },

    _callTo: function (params) {
        var returnValue = null;
        try {
            // Create the function
            var fn = eval(params.funName);
            // alternative only for global functions: window[functionName]
            if (fn === null) {
                throw("function is not defined!")
            }
            var data = eval(params.arguments);
            returnValue = fn.apply(fn, data);
            this.callback('_callTo', {
                'id': params.id,
                'type': 'success',
                'value': returnValue
            });
        } catch (e) {
            this.callback('_callTo', {
                'id': params.id,
                'type': 'error',
                'value': e.toString()
            });
        }
    },

    _cleanUp: function (id) {
        delete this._callbacks[id];
    },

    _ready: true,
    _messages: [],
    //_id_label: 'RBCFrameId_',
    _messageIdCounter: 0,
    _callbacks: {},

    _callAPIFormRuby: function (functionName, argumentsString) {
        var returnValue = null;
        try {
            //Create the function
            var fn = eval(functionName); // alternative only for global functions: window[functionName]
            if (fn === null) {
                throw("function is not defined!")
            }
            var data = eval(argumentsString);
            fn.apply(fn, data);
        } catch (e) {
            throw "Error(J): RBC.GUI.WebDialog._callAPIFormRuby:\\n" + e
        }
    }
};

RBC.GUI.WebDialog = {

    name: 'RBC.GUI.WebDialog',

    ready: function (data, success) {
        window.setTimeout(function () {
            RBC.GUI.WebDialog.callback({
                name: 'ready',
                data: data,
                success: success
            });
        }, 50);
    },

    /* @method close
     * @return {Boolean}
     * @version 2.2.0
     * */
    // close this dialog.
    close: function () {
        if (RBC.isSu) {
            this.callback('_close', true);
            return true
        } else {
            if (window.console !== undefined) {
                console.log('The dialog can only be closed in SketchUp!');
            }
            return false
        }
    },

    /* Wrapper to call any defined action_callback, handles escaping and encoding etc.
     * @params {Object} json
     * {
     *   name: string,
     *   data: json,
     *   test: function,
     *   success: function,
     *   error: function,
     *   complete: function
     * }
     * @params name, *arguments
     * @return {Boolean}
     * @since 2.2.0
     */
    callback: function () {
        // merge the given arguments with
        var opt = {
                data: null,
                success: function () {
                }, // null,
                error: function () {
                }, // null,
                complete: function () {
                }  // null
            },
            name = null,
            args = [];
        if (arguments.length === 1 && typeof(arguments[0]) === 'object') {
            json = arguments[0];
            for (var key in json) {
                opt[key] = json[key]
            }
            name = opt.name;
            args.push(opt.data);
            if (!RBC.isSu) {
                if (typeof(opt.test) === 'function') {
                    value = opt.test(args);
                    opt.success(value);
                    opt.complete(value);
                    return true;
                } else {
                    if (window.console !== undefined) {
                        console.log('Warn(J): Please add the Test function key!' + name);
                    }
                    return false;
                }
            }
        } else if (arguments.length >= 1) {
            name = arguments[0];
            args = Array.prototype.slice.call(arguments).slice(1);
            if (!RBC.isSu) {
                if (window.console !== undefined) {
                    console.log('Warn(J): Please execute it in Sketchup!');
                }
                return false
            }
        } else if (arguments.length === 1 && typeof(arguments[0]) === "string") {
            name = arguments[0];
            args = null;
            if (!RBC.isSu) {
                if (window.console !== undefined) {
                    console.log('Warn(J): Please execute it in Sketchup!');
                }
                return false
            }
        } else {
            if (window.console !== undefined) {
                console.log('Warn(J): Incorrect parameter!');
            }
            return false
        }
        var id = (this._messageIdCounter++);
        this._callbacks[id] = {
            success: opt.success,
            error: opt.error,
            complete: opt.complete
        };
        this._createMessageField(id, JSON.stringify(args));

        /*
         * OSX-Safari skips skp urls if they happen in a too short time interval.
         * We pass all skp urls through a queue that makes sure that a message is only
         * sent after the SketchUp side has received the previous message.
         * */
        this._messages.push([name, id]);
        if (!this._busy) {
            this._nextMessage()
        }
        return true;
    },

    _nextMessage: function () {
        var message = this._messages.shift();
        if (!message) {
            this._busy = false;
            return false;
        } else {
            this._busy = true;
            var url = "skp:" + message[0] + "@" + this._id_label + message[1];
            this._setLocation(url);
            return true;
        }
    },

    _busy: false,
    _messages: [],
    // Keeps track of callbacks.
    _messageIdCounter: 0,
    _callbacks: {},
    _id_label: '__<GUID>__',

    _createMessageField: function (id, value) {
        var messageField = document.createElement('input');
        messageField.setAttribute('type', 'hidden');
        messageField.setAttribute('style', 'display:none');
        messageField.setAttribute('id', 'RBC.GUI.WebDialog.' + id);
        messageField.value = value;
        document.body.appendChild(messageField);
    },
    _setLocation: function (url) {
        // allow the DOM to refresh so that the MessageField is created (from DynamicComponents dcBridge.js)
        window.setTimeout(function () {
            window.location.href = url;
        }, 0);
    },
    _cleanUp: function (id) {
        try {
            var elem = document.getElementById('RBC.GUI.WebDialog.' + id);
            elem.parentNode.removeChild(elem);
        } catch (e) {
            window.location = 'skp:_error@' + "Error(J): RBC.GUI.WebDialog._cleanUp:\\n" + e;
        } finally {
            delete this._callbacks[id];
        }
    },
    _cleanUpScripts: function () {
        // timeout to wait after injected script has been executed (otherwise this one is not removed)
        window.setTimeout(function () {
            var scripts = document.body.getElementsByTagName("script");
            for (var i = 0; i < scripts.length; i++) {
                scripts[i].parentNode.removeChild(scripts[i])
            }
        }, 0);
    },
    _fromRuby: function (id, functionName, argumentsString) {
        var returnValue = null;
        try {
            //Create the function
            var fn = eval(functionName); // alternative only for global functions: window[functionName]
            if (fn === null) {
                throw "function is not defined!"
            }
            //argumentsString = argumentsString;
            var data = eval(argumentsString);
            returnValue = fn.apply(fn, data);
        } catch (e) {
            //alert("Error(J): RBC.GUI.WebDialog._fromRuby:\\n" + e);
            window.location = 'skp:_error@' + "Error(J): RBC.GUI.WebDialog._fromRuby:\\n" + e
        } finally {
            this._createMessageField(id, JSON.stringify(returnValue));
        }
    }
};

/*
 * DialogProxy.
 * RBC::GUI::HtmlDialog包裹类底层采用的是libcef(Google Chrome内核)。
 * 可以通过判断是否为Google Chrome内核，来判断是否为RBC.GUI.HtmlDialog.
 * */
if (RBC.isChrome) {
    RBC.GUI.DialogProxy = RBC.GUI.HtmlDialog;
} else {
    RBC.GUI.DialogProxy = RBC.GUI.WebDialog;
}

/**/
RBC.log = function (info) {
    if(RBC.isChrome){
        console.log(info)
    }else{
        RBC.GUI.DialogProxy.callback({
            name: '_suLog',
            data: info
        })
    }
};

/**/
RBC.warning = function (info) {
    RBC.GUI.DialogProxy.callback({
        name: '_suWarning',
        data: info
    })
};

RBC.Language = {

    strings: {},

    /* refresh language value.
     *
     * @param [Function] callbackFun
     *
     * @return [null]
     * */
    refresh: function (callbackFun) {
        if (window.console !== undefined) {
            console.log("refresh RBC.Language.");
        }
        if (typeof(callbackFun) === "function") {
            RBC.Language._refreshFun = callbackFun;
        }
        if (RBC.isSu) {
            window.setTimeout(function () {
                RBC.GUI.DialogProxy.callback('_language', true);
            }, 30);
        } else {
            RBC.Language._refreshFun(RBC.Language)
        }
        return null;
    },

    /* Get language value.
     * @method tr
     * @param [String] key
     * @return [String]
     * @since 2.0.0
     * */
    tr: function (key) {
        if (!RBC.isSu) {
            if (window.console !== undefined) {
                console.log("RBC.Language: " + key + "<==>" + key);
            }
            return key;
        }
        if (this.strings[key]) {
            if (window.console !== undefined) {
                console.log("RBC.Language: " + key + "<==>" + this.strings[key]);
            }
            return this.strings[key];
        } else {
            RBC.GUI.DialogProxy.callback('_language_insert_key', key);
            return key;
        }
    },

    /* Refresh callback function.
     * */
    _refreshFun: function () {
    }

};

/*
 * Capture global JS errors and output to the console of SketchUp.
 * */
window.onerror = function (message, source, lineno, colno, error) {
    var data = {
        "message": message.toString(),
        "source": source.toString(),
        "lineno": lineno,
        "colno": colno.toString(),
        "error": error.toString()
    };
    if (RBC.isSu) {
        RBC.GUI.DialogProxy.callback('_error', data);
    } else {
        if (window.console !== undefined) {
            console.log(data);
        } else {
            alert(JSON.stringify(data))
        }
    }
};
