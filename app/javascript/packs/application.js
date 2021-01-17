// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

//= require jquery3

require("@rails/ujs").start()
require("turbolinks").start()
require("channels")
require("chartkick")
require("chart.js")



// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

document.addEventListener("turbolinks:load", function() {

    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    })

    var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
    var dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
        return new bootstrap.Dropdown(dropdownToggleEl)
    })
    
    $('.savings-pot').on('change', function(){
        var account_number = $(this).data("number");
        $.ajax({
            type: 'PATCH',
            url: "/account/" + $("#savings-pot"+account_number).data("account"),
            data : JSON.stringify({"savings": $("#savings-pot"+account_number).val(), "threshold_offset": $("#threshold_leave"+account_number).val()*100, "show_balance": $("#pulse-acc-bal"+account_number).is(":checked"), "show_pots": $("#pulse-pot-bal"+account_number).is(":checked"), "show_combined": $("#pulse-comb-bal"+account_number).is(":checked")}),
        });
    });
    
    $('.savings-condition-toggle').on('change', function(){
        var account_number = $(this).data("number")
        if ($(this).is(":checked")){
            $('#target-group'+account_number).prepend('<div class="input-group-text" id="target-symbol'+account_number+'">£</div>');
            $('#target'+account_number).attr('placeholder', "Minimum amount");
        } else {
            $('#target-symbol'+account_number).remove();
            $('#target'+account_number).attr('placeholder', "Description contains");
        }
    });

    $('.transfer-balance').on('click', function() {
        if (confirm('This will transfer ' + $(this).data("amount-with-currency") + " to your designated savings pot")) { 
            alert('Now transfering money, please wait.');
            $.ajax({
                type: 'GET',
                url: "/account/" + $("#acc-name-edit").data("acc") + "/transfer_to_pot/" + $(this).data("amount") + "/" + $(this).data("transaction")
            });
        } else {
            alert('No money was transfered.');
        }
    })
    $('#acc-name-edit').on('click', function() {
        var i = $('#acc-name-input');
            v = i.val();

        if ($(this).hasClass('search')) {
            $(this).text('check'); 
            $("#acc-name").remove();    
        } else {
            $(this).text('edit');
            $('<a id="acc-name"></a>').insertBefore(i);
            $("#acc-name").text(v); 
            
            $.ajax({
               type: 'PATCH',
               url: "/account/" + $("#acc-name-edit").data("acc"),
               data : JSON.stringify({"name": $('#acc-name-input').val()}),
            });
        }
        
        $(this).toggleClass('search');
    });
})