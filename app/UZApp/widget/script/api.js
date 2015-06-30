/*UZ JavaScript Library*/
(function(window){
    var u = u || {};
    u.trim = function(str){
        return str == null ? "" : String.prototype.trim.call(str)
    };
    u.addEvt = function(el, name, fn, useCapture){
        var useCapture = useCapture || false;
        if(el.addEventListener) {
            el.addEventListener(name, fn, useCapture);
        }
    };
    u.rmEvt = function(el, name, fn, useCapture){
        var useCapture = useCapture || false;
        if (el.removeEventListener) {
            el.removeEventListener(name, fn, useCapture);
        }
    };
    u.dom = function(el, selector){
        if(typeof arguments[0] == 'string'){
            if(document.querySelector){
                return document.querySelector(arguments[0]);
            }
        }else{
            if(el.querySelector){
                return el.querySelector(selector);
            }
        }
    };
    u.domAll = function(el, selector){
        if(typeof arguments[0] == 'string'){
            if(document.querySelectorAll){
                return document.querySelectorAll(arguments[0]);
            }
        }else{
            if(el.querySelectorAll){
                return el.querySelectorAll(selector);
            }
        }
    };
    u.byId = function(id){
        return document.getElementById(id);
    };
    u.prev = function(el){
        var node = el.previousSibling;
        if(node.nodeType && node.nodeType === 3){
            node = node.previousSibling;
            return node;
        }
    };
    u.next = function(el){
        var node = el.nextSibling;
        if(node.nodeType && node.nodeType === 3){
            node = node.nextSibling;
            return node;
        }
    };
    u.remove = function(el){
        if(el && el.parentNode){
            el.parentNode.removeChild(el);
        }
    };
    u.attr = function(el, name, value){
        if(arguments.length == 2){
            return el.getAttribute(name);
        }else if(arguments.length == 3){
            el.setAttribute(name, value);
            return el;
        }
    };
    u.removeAttr = function(el, name){
        if(arguments.length === 2){
            el.removeAttribute(name);
        }
    };
    u.hasCls = function(el, cls){
        if(el.className.indexOf(cls) > -1){
            return true;
        }else{
            return false;
        }
    };
    u.addCls = function(el, cls){
        if('classList' in el){
            el.classList.add(cls);
        }else{
            var preCls = el.className;
            var newCls = preCls + cls;
            el.className = newCls;
        }
        return el;
    };
    u.removeCls = function(el, cls){
        if('classList' in el){
            el.classList.remove(cls);
        }else{
            var preCls = el.className;
            var newCls = preCls.replace(cls, '');
            el.className = newCls;
        }
        return el;
    };
    u.toggleCls = function(el, cls){
       if('classList' in el){
            el.classList.toggle(cls);
        }else{
            if(u.hasCls(el, cls)){
                u.addCls(el, cls);
            }else{
                u.removeCls(el, cls);
            }
        }
        return el; 
    };
    u.val = function(el){
        switch(el.tagName){
            case 'SELECT':
                var value = el.options[el.selectedIndex].value;
                return value;
                break;
            case 'INPUT' || 'TEXTAREA':
                return el.value;
                break;
        }
    };
    u.html = function(el, html){
        if(arguments.length === 1){
            return el.innerHTML;
        }else if(arguments.length === 2){
            el.innerHTML = html;
            return el;
        }
    };
    u.text = function(el, txt){
        if(arguments.length === 1){
            return el.textContent;
        }else if(arguments.length === 2){
            el.textContent = txt;
            return el;
        }
    };
    u.offset = function(el){
        return {
            w: el.offsetWidth,
            h: el.offsetHeight,
            l: el.offsetLeft,
            t: el.offsetTop
        }
    };
    u.css = function(el, css){
        if(typeof css == 'string'){
            var preCss = el.style.cssText;
            el.style.cssText = preCss + css;
        }
    };
    u.setStorage = function(key, value){
        if(arguments.length === 2){
            var v = value;
            if(typeof v == 'object'){
                v = JSON.stringify(v);
            }else{
                v = v+'';
            }
            window.localStorage.setItem(key, v);
        }
    };
    u.getStorage = function(key){
        var v = window.localStorage.getItem(key);
        return v;
    };
    u.rmStorage = function(key){
        if(key){
            window.localStorage.removeItem(key);
        }
    };
    u.clearStorage = function(){
        window.localStorage.clear();
    };
    

    window.$api = u;

})(window);