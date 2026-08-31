        </main>
        <nav class="bottom-nav" aria-label="Navegação rápida">
            <a href="/dashboard" class="bottom-nav-item <?= $uriAtual === '/dashboard' ? 'active' : '' ?>"><span class="nav-icon" data-icon="home"></span><small>Início</small></a>
            <a href="/lancamentos" class="bottom-nav-item <?= str_starts_with($uriAtual, '/lancamentos') ? 'active' : '' ?>"><span class="nav-icon" data-icon="list"></span><small>Movimentos</small></a>
            <a href="/lancamentos/novo" class="bottom-add"><span>+</span><small>Lançar</small></a>
            <a href="/contas" class="bottom-nav-item <?= str_starts_with($uriAtual, '/contas') ? 'active' : '' ?>"><span class="nav-icon" data-icon="wallet"></span><small>Contas</small></a>
            <button type="button" class="bottom-nav-item" data-nav-open><span class="nav-icon" data-icon="menu"></span><small>Menu</small></button>
        </nav>
    </div>
</div>
<script src="/assets/js/app.js"></script>
<script>if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(function () {});</script>
</body>
</html>
