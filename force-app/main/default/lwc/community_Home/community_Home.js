import { LightningElement, track, api } from 'lwc';
import global from 'c/utils';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import swiper from '@salesforce/resourceUrl/swiperjs';
import swiperNew from '@salesforce/resourceUrl/Swiper8';

//import addtionalCss from '@salesforce/resourceUrl/addtionalSw';

export default class Community_Home extends LightningElement {
    @track isFirstRender = true;
    @track showSpinner = false;

    @api customStyle = {
        css : `
        * {
            font-family:'AppleSDGothicNeo';
            word-break:break-all!important;
        }
        `
        , id : 'cStyle'
    };

    @api jquery = {
        src : 'https://code.jquery.com/jquery-3.4.1.min.js'
    };

    async connectedCallback() {
        global.setCustomStyle(this.customStyle.css, this.customStyle.id);
        // global.setCustomScript(this.jquery.src);
        loadStyle(this, swiper + '/swiper-4.5.1/dist/css/swiper.min.css');
        // loadStyle(this, swiperNew + '/swiper-8.4.2/package/swiper-bundle.min.css');
       // loadStyle(this, addtionalCss).then(() => {
       //     console.log('It`s Done!!');
       // });
    }

    renderedCallback() {
        if(this.isFirstRender) {
            loadScript(this, swiper + '/swiper-4.5.1/dist/js/swiper.min.js')
            // loadScript(this, swiperNew + '/swiper-8.4.2/package/swiper-bundle.min.js')
            .then(() => {
                console.log('Javascript File callout Success');
                this.handleSwiper();
            }).catch(e => {
                console.log(e);
                console.log('It`s Error TT');
            });
        }

        this.isFirstRender = false;
    }

    handleSwiper() {
        console.log('hello~');

        let swiperContainer = this.template.querySelector('.swiper');
        let swiperNext = this.template.querySelector('.swiper-button-next');
        let swiperPrev = this.template.querySelector('.swiper-button-prev');
        let swiperPage = this.template.querySelector('.swiper-pagination');

        try {
            var b_Swiper = new Swiper(swiperContainer, {
                cssMode: true,
                navigation: {
                    nextEl: swiperNext,
                    prevEl: swiperPrev,
                },
                pagination: {
                    el: swiperPage,
                },
                mousewheel: true,
                keyboard: true,
            });

            // const swiper_val = new Swiper(".swiper", {
            //     // If we need pagination
            //     pagination: {
            //         el: '.swiper-pagination',
            //     },
            
            //     // Navigation arrows
            //     navigation: {
            //         nextEl: '.swiper-button-next',
            //         prevEl: '.swiper-button-prev',
            //     },
            // });
            // console.log(swiper_val)
            // console.log(this.template.querySelector('.swiperX'));
        } catch(error) {
            console.log(error);
        }
    }
}