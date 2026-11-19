/* Hiện/ẩn mật khẩu dùng chung — event delegation, hoạt động cả với nội dung render sau. */
(function () {
  'use strict';

  document.addEventListener('click', function (event) {
    var toggle = event.target.closest('[data-pw-toggle]');
    if (!toggle) return;

    var wrap = toggle.closest('.input-wrap');
    var input = wrap ? wrap.querySelector('input') : null;
    if (!input) return;

    var show = input.type === 'password';
    input.type = show ? 'text' : 'password';

    toggle.setAttribute('aria-pressed', show ? 'true' : 'false');
    toggle.setAttribute('aria-label', show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu');

    var use = toggle.querySelector('use');
    if (use) use.setAttribute('href', show ? '#i-eye-off' : '#i-eye');

    // Giữ focus trên nút để người dùng bàn phím có thể bấm tiếp.
    toggle.focus({ preventScroll: true });
  });
})();
