import { LightningElement, api } from 'lwc';

export default class De_Public_Svg extends LightningElement {
    @api tag;

    renderedCallback (){
        this.template.querySelector('span').innerHTML = this.tag;
    }
}