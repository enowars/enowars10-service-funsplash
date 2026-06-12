export function submit_native(formId) {
    const form = document.getElementById(formId);
    if (form) {
        form.submit();
    }
}
