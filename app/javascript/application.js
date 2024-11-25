// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

import jquery from 'jquery';
import * as bootstrap from "bootstrap"
import 'admin-lte';
import 'admin-lte/dist/js/adminlte.min.js';

import 'bootstrap/dist/css/bootstrap.min.css';
import 'admin-lte/dist/css/adminlte.min.css';

window.jQuery = jquery;
window.$ = jquery;
$(document).ready(function() {
    console.log("jQuery is working!");
});

// // Enables Service Worker Registration
// if ('serviceWorker' in navigator) {
//     navigator.serviceWorker.register('/serviceworker.js')
//         .then(function(registration) {
//             console.log('ServiceWorker registered: ', registration);
//         })
//         .catch(function(error) {
//             console.log('ServiceWorker registration failed: ', error);
//         });
// }