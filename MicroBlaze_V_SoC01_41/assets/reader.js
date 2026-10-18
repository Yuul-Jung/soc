/* (추가) 오프라인 문서 탐색. 실습 소스와 독립적으로 동작한다. */
(() => {
  'use strict';
  const nav = document.querySelector('.flow-nav');
  const live = document.createElement('p');
  live.className = 'reader-sr'; live.setAttribute('role', 'status');
  document.body.append(live);
  const normalized = value => value.normalize('NFKC').toLocaleLowerCase().replace(/\s+/g, ' ').trim();
  if (nav) {
    const links = [...nav.querySelectorAll('.timeline a[href^="#"]')];
    const entries = links.map(a => ({a, target: document.getElementById(a.hash.slice(1))})).filter(x => x.target);
    const box = document.createElement('div'); box.className = 'reader-search';
    box.innerHTML = '<label for="section-filter">이 장의 절 찾기</label><input id="section-filter" type="search" placeholder="절 제목 또는 본문 검색" autocomplete="off"><p class="reader-count" role="status"></p>';
    nav.insertBefore(box, nav.querySelector('.timeline'));
    const input = box.querySelector('input'), count = box.querySelector('.reader-count');
    entries.forEach(x => { x.search = normalized(x.target.textContent + ' ' + x.a.textContent); });
    const filter = () => {
      const words = normalized(input.value).split(' ').filter(Boolean);
      let visible = 0;
      entries.forEach(x => { const match = words.every(w => x.search.includes(w)); x.a.closest('li').hidden = !match; if (match) visible++; });
      count.textContent = words.length ? `${visible}개 절 · 본문은 그대로 표시됩니다` : `${entries.length}개 절`;
    };
    input.addEventListener('input', filter);
    input.addEventListener('keydown', e => { if(e.key === 'Escape') { input.value = ''; filter(); } });
    filter();
    let pending = false;
    const update = () => {
      pending = false;
      let current = entries[0];
      for (const entry of entries) { if(entry.target.getBoundingClientRect().top <= 100) current = entry; }
      entries.forEach(x => { const active = x === current; x.a.classList.toggle('active', active); if(active) x.a.setAttribute('aria-current','location'); else x.a.removeAttribute('aria-current'); });
    };
    window.addEventListener('scroll', () => { if(!pending) { pending = true; requestAnimationFrame(update); } }, {passive:true});
    links.forEach(a => a.addEventListener('click', () => {
      const target = document.getElementById(a.hash.slice(1));
      if(target) { target.setAttribute('tabindex', '-1'); target.focus({preventScroll:true}); }
    }));
    update();
  }
  const picker = document.querySelector('.reader-chapter-select');
  if (picker) picker.closest('form').hidden = false;
  if (picker) picker.closest('form').addEventListener('submit', e => { e.preventDefault(); location.href = picker.value; });
  document.querySelectorAll('main pre').forEach((pre, i) => {
    const button = document.createElement('button'); button.type = 'button'; button.className = 'reader-copy';
    button.textContent = '코드 복사'; button.setAttribute('aria-label', `코드 블록 ${i + 1} 복사`);
    const bar = document.createElement('div'); bar.className = 'reader-code-tools'; bar.append(button); pre.before(bar);
    const text = () => pre.textContent;
    button.addEventListener('click', async () => {
      let copied = false;
      try { if(navigator.clipboard && window.isSecureContext) { await navigator.clipboard.writeText(text()); copied = true; } } catch (_) {}
      if(!copied) {
        const scratch = document.createElement('textarea'); scratch.value = text(); scratch.className = 'reader-copy-buffer'; document.body.append(scratch); scratch.select();
        try { copied = document.execCommand('copy'); } catch (_) {}
        scratch.remove(); button.focus({preventScroll:true});
      }
      if(copied) { button.textContent = '복사됨'; live.textContent = `코드 블록 ${i + 1} 복사 완료`; }
      else { const range = document.createRange(); range.selectNodeContents(pre); const sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(range); live.textContent = '코드를 선택했습니다. Ctrl+C 또는 Command+C로 복사하세요.'; }
      setTimeout(() => { button.textContent = '코드 복사'; }, 1800);
    });
  });
  const catalog = document.querySelector('[data-course-filter]');
  if(catalog) {
    const cards = [...document.querySelectorAll('article.card')];
    const groups = [...document.querySelectorAll('section.group[id^="group"]')];
    const status = document.querySelector('#course-filter-status');
    catalog.addEventListener('input', () => {
      const terms = normalized(catalog.value).split(' ').filter(Boolean); let count=0;
      cards.forEach(card => { card.hidden = !terms.every(t => normalized(card.textContent).includes(t)); if(!card.hidden) count++; });
      groups.forEach(group => { group.hidden = ![...group.querySelectorAll('article.card')].some(c => !c.hidden); });
      status.textContent = `${count}개 장`;
    });
    catalog.addEventListener('keydown', e => {if(e.key==='Escape'){catalog.value='';catalog.dispatchEvent(new Event('input'));}});
  }
})();
