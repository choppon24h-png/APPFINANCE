<?php
$ehTermos = ($pagina ?? 'termos') === 'termos';
$atualizado = '27 de novembro de 2026';
?>
<article class="legal-page">
    <span class="draft-badge">[RASCUNHO — revisar com jurídico]</span>
    <h1><?= $ehTermos ? 'Termos de Uso' : 'Política de Privacidade' ?></h1>
    <p class="legal-updated">Última atualização: <?= $atualizado ?></p>

    <p class="legal-lead">
        Este documento é um modelo inicial preparado para o SOMASE — Controle Financeiro e precisa ser revisado
        por um profissional jurídico antes de ser considerado definitivo. Ele descreve, de forma transparente,
        como o sistema funciona e como os dados pessoais são tratados, em linha com a Lei Geral de Proteção de
        Dados (Lei nº 13.709/2018 — LGPD).
    </p>

    <?php if ($ehTermos): ?>
        <h2>1. O que é o SOMASE</h2>
        <p>O SOMASE é uma aplicação de controle financeiro pessoal que permite registrar receitas, despesas, contas, investimentos e acompanhar relatórios. O acesso é individual: cada conta enxerga apenas os próprios dados financeiros.</p>

        <h2>2. Cadastro e conta</h2>
        <p>Para usar o sistema é necessário criar uma conta com nome completo, e-mail válido, data de nascimento e senha própria, ou entrar com uma conta Google/Microsoft. É necessário ter pelo menos <?= (int) ($_ENV['REGISTRATION_MIN_AGE'] ?? 18) ?> anos.</p>
        <p>Você é responsável por manter a confidencialidade da sua senha e por todas as atividades realizadas na sua conta. Em caso de uso indevido, fale com o administrador.</p>

        <h2>3. Uso adequado</h2>
        <p>Você se compromete a não utilizar o sistema para atividades ilícitas, não tentar acessar contas de terceiros e não comprometer a segurança ou a disponibilidade da aplicação.</p>

        <h2>4. Disponibilidade</h2>
        <p>Buscamos manter o serviço disponível de forma contínua, mas ele pode passar por manutenções programadas ou interrupções eventuais. O sistema é fornecido no estado em que se encontra, sem garantia de adequação a um propósito específico.</p>

        <h2>5. Conteúdo do usuário</h2>
        <p>Os lançamentos, contas e investimentos cadastrados são de sua responsabilidade. O SOMASE não presta consultoria financeira, contábil ou de investimentos: as informações servem apenas para organização pessoal.</p>

        <h2>6. Encerramento</h2>
        <p>Você pode solicitar o encerramento da conta ao administrador. Podemos suspender contas que violem estes termos ou que apresentem risco à segurança do sistema.</p>

        <h2>7. Contato</h2>
        <p>Dúvidas sobre estes termos: <a href="mailto:<?= htmlspecialchars($contato) ?>"><?= htmlspecialchars($contato) ?></a>.</p>
    <?php else: ?>
        <h2>1. Quais dados coletamos</h2>
        <ul>
            <li><strong>Dados de cadastro:</strong> nome completo, e-mail, data de nascimento, data de aceite dos termos e endereço IP do cadastro.</li>
            <li><strong>Dados de autenticação:</strong> senha armazenada apenas como hash (nunca em texto legível) e, no login social, o identificador da conta Google/Microsoft.</li>
            <li><strong>Dados financeiros:</strong> contas, lançamentos, categorias, centros de custo e investimentos que você mesmo cadastra.</li>
            <li><strong>Registros técnicos:</strong> data e hora de acesso, navegador e tentativas de login, usados para segurança.</li>
        </ul>

        <h2>2. Para que usamos os dados</h2>
        <p>Para autenticar seu acesso, exibir seus próprios dados financeiros, calcular relatórios, prevenir fraudes e abusos (limite de tentativas de login e de cadastros) e cumprir obrigações legais.</p>

        <h2>3. Base legal (LGPD)</h2>
        <p>O tratamento se apoia na execução de contrato (art. 7º, V), no cumprimento de obrigação legal (art. 7º, II) e no legítimo interesse para segurança da aplicação (art. 7º, IX), sempre limitado à finalidade informada.</p>

        <h2>4. Compartilhamento</h2>
        <p>Não vendemos dados pessoais. O compartilhamento ocorre apenas com provedores necessários ao funcionamento (hospedagem e, se você optar, Google ou Microsoft para autenticação) e com autoridades quando houver determinação legal.</p>

        <h2>5. Cookies e sessão</h2>
        <p>Utilizamos cookies estritamente necessários para manter sua sessão autenticada e para segurança (CSRF). Não usamos cookies de publicidade. O navegador pode armazenar apenas o seu e-mail na tela de login, caso você marque “Lembrar meu e-mail”.</p>

        <h2>6. Segurança</h2>
        <p>Adotamos senhas com hash, proteção CSRF, controle de sessão, limite de tentativas de login e registro de auditoria das ações administrativas. Nenhum sistema é totalmente imune a incidentes; em caso de incidente relevante, os titulares serão comunicados.</p>

        <h2>7. Seus direitos</h2>
        <p>Você pode solicitar confirmação de tratamento, acesso, correção, portabilidade, anonimização ou exclusão dos seus dados, além de revogar consentimentos. Pedidos podem ser feitos ao administrador da conta.</p>

        <h2>8. Retenção e exclusão</h2>
        <p>Os dados são mantidos enquanto a conta existir ou enquanto houver obrigação legal de guarda. Após a exclusão, os registros financeiros são removidos e os logs de auditoria podem ser mantidos de forma mínima para segurança.</p>

        <h2>9. Encarregado / contato</h2>
        <p>Solicitações relacionadas à LGPD: <a href="mailto:<?= htmlspecialchars($contato) ?>"><?= htmlspecialchars($contato) ?></a>.</p>
    <?php endif; ?>

    <p class="legal-note">Este texto é um modelo e não substitui orientação jurídica especializada. Ajuste razão social, endereço, prazos e canal do encarregado antes da publicação.</p>
</article>
