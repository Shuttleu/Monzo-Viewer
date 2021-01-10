// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

//= require jquery3

require("@rails/ujs").start()
require("turbolinks").start()
require("channels")
require("bootstrap/dist/js/bootstrap")



// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

document.addEventListener("turbolinks:load", function() {

    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    })
    
    $('.savings-pot').on('change', function(){
        console.log("fired");
        update_savings($(this).data("number"));
    });

    function update_savings(savings_number) {
        console.log(savings_number)
        $.ajax({
            type: 'PATCH',
            url: "/account/" + $("#savings-pot"+savings_number).data("account") + "/savings_pot",
            data : JSON.stringify({"new_pot": $("#savings-pot"+savings_number).val(), "threshold": $("#threshold"+savings_number).val(), "threshold_leave": $("#threshold_leave"+savings_number).val()}),
            processData: false,
            contentType: 'application/merge-patch+json',
         
         },
         function(data, status){
           alert("Data: " + data + "\nStatus: " + status);
         });
    };
    $('.transfer-balance').on('click', function() {
        if (confirm('This will transfer ' + $(this).data("amount-with-currency") + " to your designated savings pot")) { 
            alert('Now transfering money, please wait.');
            $.ajax({
                type: 'GET',
                url: "/account/" + $("#acc-name-edit").data("acc") + "/transfer_to_pot/" + $(this).data("amount") + "/" + $(this).data("transaction"),
                processData: false,
                contentType: 'application/merge-patch+json',
            
            },
            function(data, status){
            alert("Data: " + data + "\nStatus: " + status);
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
               url: "/account/" + $("#acc-name-edit").data("acc") + "/name",
               data : JSON.stringify({"new_name": $('#acc-name-input').val()}),
               processData: false,
               contentType: 'application/merge-patch+json',
            
               /* success and error handling omitted for brevity */
            },
            function(data, status){
              alert("Data: " + data + "\nStatus: " + status);
            });
        }
        
        $(this).toggleClass('search');
    });
})