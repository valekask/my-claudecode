# Security Checklist

Source: docs/CLAUDE.md, OWASP Top 10, code-foundations cc-defensive-programming

---

## Secrets & Configuration

- [ ] **SE-1**: "Are there hardcoded URLs, tokens, API keys, or credentials in the code?"
  → Search: Grep for patterns like `http://`, `https://`, `Bearer`, `token`, `apiKey`, `password`, `secret`, base64-encoded strings.
  → FAIL: Any hardcoded secret, URL, or credential found. Must use `environment.ts` or `EnvironmentConfigService`.

- [ ] **SE-2**: "Does configuration use environment.ts or EnvironmentConfigService?"
  → Check: All environment-dependent values (API URLs, feature flags, keys) come from environment files or config service.
  → FAIL: Values that differ between environments are hardcoded in component/service code.

- [ ] **SE-3**: "Are sensitive data excluded from logs?"
  → Check: `console.log`, logging services, and error reporters don't include passwords, tokens, PII, or full request/response bodies with sensitive fields.
  → FAIL: `console.log('user:', user)` where `user` contains password, email, or token fields.

- [ ] **SE-4**: "Are sensitive data excluded from serialization (JSON.stringify, API responses)?"
  → Check: Objects sent to the client or serialized don't include internal fields (passwords, tokens, internal IDs).
  → FAIL: Full entity with sensitive fields passed to template or returned in API response without field filtering.

## Input Validation & Injection

- [ ] **SE-5**: "Is all user input validated at system boundaries?"
  → Check: Data from forms, URL params, query strings, and external APIs is validated before use (type, format, range).
  → FAIL: User input flows directly into business logic, template rendering, or API calls without validation.

- [ ] **SE-6**: "Is there no string interpolation in queries, selectors, or commands?"
  → Check: No template literals or string concatenation used to build database queries, CSS selectors, or shell commands with user input.
  → FAIL: `` `SELECT * FROM users WHERE id = ${userId}` `` or `` document.querySelector(`.item-${userInput}`) ``.

- [ ] **SE-7**: "Is there no `eval()`, `new Function()`, or dynamic code execution?"
  → Check: No dynamic code evaluation from user-controlled input.
  → FAIL: `eval(userExpression)` or `new Function('return ' + userInput)()` found anywhere.

- [ ] **SE-8**: "Is there no direct `innerHTML` with unsanitized content?"
  → Check: Dynamic HTML content uses Angular's DomSanitizer (`bypassSecurityTrustHtml` only with trusted input) or `textContent` for plain text.
  → FAIL: `element.innerHTML = userInput` or `[innerHTML]="untrustedData"` without sanitization.

## Authentication & Authorization

- [ ] **SE-9**: "Are auth checks performed before resource access?"
  → Check: Protected routes have guards. Protected API calls check authorization before returning data.
  → FAIL: A route or resource is accessible without proper authentication/authorization check.

- [ ] **SE-10**: "Do error messages avoid revealing system internals?"
  → Check: Error messages shown to users don't include stack traces, internal paths, database schema, or server configuration.
  → FAIL: Error handler returns `error.stack` or `error.message` containing internal details to the UI.

## Async & Network

- [ ] **SE-11**: "Are all unhandled Promise rejections caught?"
  → Check: Every `async/await` has try-catch. Every `.then()` has `.catch()`. Effects have `catchError`.
  → FAIL: An async operation without error handling — unhandled rejection could crash the app or leak error details.

- [ ] **SE-12**: "Are outbound URLs validated (no SSRF from user-controlled URLs)?"
  → Check: If the app makes HTTP requests to URLs constructed from user input, those URLs are validated against an allowlist.
  → FAIL: User-provided URL used directly in `HttpClient.get(userUrl)` without validation.

## Dependencies & Files

- [ ] **SE-13**: "Are file paths validated (no path traversal with `../`)?"
  → Check: If the app handles file paths from user input, they are sanitized to prevent directory traversal.
  → FAIL: User input used in file path without stripping `../` or validating against allowed directories.

## Protected Files

- [ ] **SE-15**: "Do new `.ts` files include the required license header?"
  → Check: New TypeScript files have the project's license header at the top of the file.
  → FAIL: New `.ts` file missing license header.

---

Total items: 14
