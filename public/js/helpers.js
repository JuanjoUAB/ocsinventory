function showDataInModalDT(title = "Information", idModal = "modal", callableFunc = {}, callOnHide = {}) {

    $('#' + idModal + ' .modal-title').text(title);
    callableFunc();
    $('#' + idModal).modal('show').on('show.bs.modal', function() {
        $.blockUI();
    }).on('shown.bs.modal', function() {
        $.unblockUI();
    }).on('hidden.bs.modal', function() {
        callOnHide();
    });
}
