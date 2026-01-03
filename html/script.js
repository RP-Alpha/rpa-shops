window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'open') {
        document.getElementById('app').classList.remove('hidden');
        document.getElementById('shop-title').innerText = data.label;
        renderItems(data.items);
    } else if (data.action === 'close') {
        closeShop();
    }
});

function renderItems(items) {
    const grid = document.getElementById('items-grid');
    grid.innerHTML = '';

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'item-card';
        div.innerHTML = `
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-price">$${item.price}</div>
            </div>
            <button class="buy-btn" onclick="buyItem('${item.name}')">Buy</button>
        `;
        grid.appendChild(div);
    });
}

function closeShop() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
}

function buyItem(itemName) {
    fetch(`https://${GetParentResourceName()}/buy`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ item: itemName })
    });
}
