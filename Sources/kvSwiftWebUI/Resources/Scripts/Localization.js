/*
Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
SPDX-License-Identifier: GPL-3.0-or-later

Localization.js
kvSwiftWebUI

Created by Svyatoslav Popov on 01.05.2024.
*/

(() => {
    const URL_QUERY_NAME = 'hl';

    if (new URLSearchParams(document.location.search).has(URL_QUERY_NAME)) { return; }

    const languageTag = document.documentElement.getAttribute('lang');
    if (languageTag === null) { return; }

    const urlQueryItem = `${URL_QUERY_NAME}=${languageTag}`;

    // Replacing local references.
    document.addEventListener("DOMContentLoaded", (event) => {
        document.body
            .querySelectorAll(`[href*="${urlQueryItem}"]`)
            .forEach((element) => {
                const href = element.getAttribute('href');
                if (href === null || !href.startsWith('/')) { return; }

                let url = new URL(href, document.location.origin);
                url.searchParams.delete(URL_QUERY_NAME, languageTag);

                element.setAttribute('href', url.href);
            });
    });
})();
