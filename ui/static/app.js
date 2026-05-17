function downloadItem(title, url, btn) {
    const card = btn.closest('.card, tr');
    const qualitySelect = card.querySelector('.quality-select');
    const quality = qualitySelect ? qualitySelect.value : 'Original';

    fetch('/api/download', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            title: title,
            url: url,
            quality: quality
        })
    })
    .then(response => response.json())
    .then(data => {
        btn.innerText = 'Queued';
        btn.classList.replace('btn-primary', 'btn-success');
        btn.classList.replace('btn-outline-primary', 'btn-success');
        btn.disabled = true;
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Failed to queue download');
    });
}

function refreshPlaylist(btn) {
    const originalText = btn.innerText;
    btn.innerText = 'Refreshing...';
    btn.disabled = true;

    fetch('/api/refresh', {
        method: 'POST'
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Refresh failed');
        }
        return response.json();
    })
    .then(data => {
        window.location.reload();
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Failed to refresh playlist');
        btn.innerText = originalText;
        btn.disabled = false;
    });
}
