import { NavigationMixin } from "lightning/navigation";

import uId from '@salesforce/user/Id';

/* Global Attribute */
isLogin = false;
userId = uId;

/* [S] global init 메서드 */
(function(){
    console.log('userId ==> ', userId);
})();    
/* [E] global init 메서드 */


/** LWC : navigateToURL */
export function gotoLink(_this, event, target) {
    // console.log('passed');
    // console.log(_this);
    // console.log(event);
    // console.log(target);

    /*let spinner = document.createElement('aside');
    spinner.innerHTML = '<lightning-spinner class="slds-spinner_container"><div role="status" class="slds-spinner slds-spinner_medium"><div class="slds-spinner__dot-a"></div><div class="slds-spinner__dot-b"></div></div></lightning-spinner>';
    document.body.appendChild(spinner);*/

    _this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
            url: target
        }
    });
}


/* [S] CustomStyle */
export function setCustomStyle(style, id) {
    let styleElement = document.createElement("style");
    styleElement.setAttribute("id", id);
    styleElement.innerHTML = style;
    document.body.appendChild(styleElement);
}

export function removeCustomStyle(id) {
    const target = document.querySelector("style#" + id);
    if(target) target.remove();
}
/* [E] CustomStyle */

export function setCustomScript(src) {
    let scriptElement = document.createElement('script');
    scriptElement.setAttribute("src", src);
    document.body.appendChild(scriptElement);
}


export function clone(obj) {
    console.log('It`s Work?');

    return JSON.parse(JSON.stringify(obj));
}