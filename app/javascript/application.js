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
    let url = window.location;
    // Sidebar search
    //     init     : Init’s the SidebarSearch Plugin and registers all visible menu items
    //     toggle   : Toggles the search dropdown list
    //     close    : Closes the search dropdown list
    //     open     : Opens the search dropdown list
    //     search   : Triggers a search
    $('[data-widget="sidebar-search"]').SidebarSearch('init')

    // Sidebar active link
    /*** add active class and stay opened when selected ***/
    // for sidebar menu entirely but not cover treeview
    $('ul.nav-sidebar a').filter(function() {
        if (this.href) {
            return this.href == url || url.href.indexOf(this.href) == 0;
        }
    }).addClass('active');
    // for the treeview
    $('ul.nav-treeview a').filter(function() {
        if (this.href) {
            return this.href == url || url.href.indexOf(this.href) == 0;
        }
    }).parentsUntil(".nav-sidebar > .nav-treeview").addClass('menu-open').prev('a').addClass('active');

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