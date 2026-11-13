// Annotated screenshot: frames the element that shows the problem, draws a callout with
// "Expected / Actual" and an arrow to the element, screenshots the viewport, then removes the
// overlay (the page is left as it was).
//
// Copy this file to a scratch path, edit CFG, then run it in the live session:
//   playwright-cli -s=<session> run-code --filename <copy>.js
// Prints "saved <path>", or throws "annotate: target not visible: <selector>".
async page => {
    const CFG = {
        target: 'role=button[name="Undo"]', // element that shows the problem (same selector rules as the skill)
        kind: 'fail', // 'fail' (red) or 'warn' (amber)
        heading: 'Undo is enabled right after opening', // the problem in one line
        expected: 'Undo disabled (nothing was changed).',
        actual: 'Undo enabled ~1 s after load.',
        note: '', // optional extra line (a question, a caveat)
        box: null, // optional callout position in viewport px, e.g. { x: 600, y: 440, w: 600 };
        //            null = placed automatically above or below the target
        out: '<output dir>/S-n-<what>-annotated.png'
    };
    const el = page.locator(CFG.target).first();
    await el.scrollIntoViewIfNeeded();
    await el.evaluate(e => e.scrollIntoView({ block: 'center', inline: 'nearest' })); // room for the callout
    const r = await el.boundingBox();
    if (!r) {
        throw new Error('annotate: target not visible: ' + CFG.target);
    }
    await page.evaluate(({ r, c }) => {
        const color = c.kind === 'warn' ? '#f59e0b' : '#e53935';
        const esc = s => s.replace(/[&<>]/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[ch]);
        const root = document.createElement('div');
        root.id = '__annot';
        root.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483647;font-family:Arial,sans-serif';
        const pad = 4;
        const frame = document.createElement('div');
        frame.style.cssText = `position:fixed;left:${r.x - pad}px;top:${r.y - pad}px;width:${r.width + 2 * pad}px;` +
            `height:${r.height + 2 * pad}px;border:4px solid ${color};border-radius:4px;box-sizing:border-box;` +
            'box-shadow:0 0 0 3px #fff, 0 0 8px 3px rgba(255,255,255,.9)';
        const w = c.box?.w ?? Math.min(640, innerWidth - 40);
        const box = document.createElement('div');
        box.style.cssText = `position:fixed;left:0;top:0;width:${w}px;background:#fff;` +
            `border:2px solid ${color};border-radius:8px;padding:14px 20px;box-shadow:0 4px 14px rgba(0,0,0,.25);` +
            'font-size:15px;line-height:1.55;color:#222;box-sizing:border-box';
        box.innerHTML = `<div style="color:${color};font-weight:bold;font-size:19px;margin-bottom:6px">${esc(c.heading)}</div>` +
            `<div><b>Expected:</b> ${esc(c.expected)}</div><div><b>Actual:</b> ${esc(c.actual)}</div>` +
            (c.note ? `<div>${esc(c.note)}</div>` : '');
        root.append(frame, box);
        document.body.append(root);
        // Position: given, or auto — centred on the target, in the larger free space above/below it.
        const h = box.getBoundingClientRect().height;
        const gap = 60;
        const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), Math.max(lo, hi));
        const x = c.box ? c.box.x : clamp(r.x + r.width / 2 - w / 2, 20, innerWidth - w - 20);
        const below = innerHeight - (r.y + r.height) >= r.y;
        const y = c.box ? c.box.y : below
            ? clamp(r.y + r.height + gap, 20, innerHeight - h - 20)
            : clamp(r.y - gap - h, 20, innerHeight - h - 20);
        box.style.left = x + 'px';
        box.style.top = y + 'px';
        const b = box.getBoundingClientRect();
        const tx = r.x + r.width / 2;
        const ty = r.y + r.height / 2;
        const sx = Math.min(Math.max(tx, b.left + 20), b.right - 20);
        const sy = ty < b.top ? b.top : ty > b.bottom ? b.bottom : b.top;
        const ex = tx;
        const ey = ty < b.top ? r.y + r.height + pad + 4 : ty > b.bottom ? r.y - pad - 4 : ty;
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', innerWidth);
        svg.setAttribute('height', innerHeight);
        svg.style.cssText = 'position:fixed;left:0;top:0';
        svg.innerHTML = `<defs><marker id="__ah" markerWidth="8" markerHeight="8" refX="5" refY="4" orient="auto">` +
            `<path d="M0,0 L8,4 L0,8 z" fill="${color}"/></marker></defs>` +
            `<line x1="${sx}" y1="${sy}" x2="${ex}" y2="${ey}" stroke="#fff" stroke-width="7"/>` +
            `<line x1="${sx}" y1="${sy}" x2="${ex}" y2="${ey}" stroke="${color}" stroke-width="4" marker-end="url(#__ah)"/>`;
        root.insertBefore(svg, box);
    }, { r, c: CFG });
    await page.screenshot({ path: CFG.out });
    await page.evaluate(() => document.getElementById('__annot')?.remove());
    return 'saved ' + CFG.out;
}
