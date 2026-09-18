document.addEventListener("DOMContentLoaded", () => {
  const root = document.documentElement;
  const themeToggle = document.getElementById("theme-toggle");
  const savedTheme = localStorage.getItem("theme");
  if (savedTheme === "dark" || savedTheme === "light") root.dataset.theme = savedTheme;

  themeToggle?.addEventListener("click", () => {
    const theme = root.dataset.theme === "dark" ? "light" : "dark";
    root.dataset.theme = theme;
    localStorage.setItem("theme", theme);
  });

  document.querySelectorAll(".filter-btn").forEach((button) => {
    button.addEventListener("click", () => {
      document.querySelectorAll(".filter-btn").forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
    });
  });

  document.querySelectorAll("[data-lang-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const lang = button.dataset.langToggle;
      document.querySelectorAll("[data-lang-toggle]").forEach((item) => {
        item.classList.toggle("is-active", item === button);
      });
      document.querySelectorAll("[data-lang-block]").forEach((block) => {
        const isVisible = block.dataset.langBlock === lang;
        block.hidden = !isVisible;
      });
      const pageTitle = document.querySelector(".hero-title");
      if (pageTitle) {
        pageTitle.textContent = lang === "pt" ? "Sobre o StreamDownload" : "About StreamDownload";
      }
      const subtitle = document.querySelector(".hero-subtitle");
      if (subtitle) {
        subtitle.textContent = lang === "pt"
          ? "Uma ideia simples que começou como solução prática e cresceu como projeto de aprendizagem, tecnologia e persistência."
          : "A simple idea that started as a practical solution and grew into a project about learning, curiosity, and persistence.";
      }
    });
  });

  const form = document.getElementById("home-form");
  if (form) setupHome(form);
  document.querySelectorAll("#home-form, .results-search-form").forEach(setupSearchSuggestions);
});

function setupSearchSuggestions(form) {
  const input = form.querySelector('input[name="q"]');
  const suggestions = form.parentElement.querySelector(".search-suggestions");
  if (!input || !suggestions) return;

  let timer;
  let controller;
  input.addEventListener("input", () => {
    clearTimeout(timer);
    if (controller) controller.abort();
    const query = input.value.trim();
    suggestions.hidden = true;
    suggestions.replaceChildren();
    if (query.length < 2 || /^https?:\/\//i.test(query)) return;

    timer = setTimeout(async () => {
      controller = new AbortController();
      try {
        const response = await fetch(`/search?q=${encodeURIComponent(query)}&page=1`, {
          credentials: "same-origin",
          signal: controller.signal
        });
        if (!response.ok) return;
        const html = await response.text();
        const documentFragment = new DOMParser().parseFromString(html, "text/html");
        const titles = [...documentFragment.querySelectorAll(".media-card .card-title")]
          .map((title) => title.textContent.trim())
          .filter(Boolean)
          .slice(0, 6);
        if (!titles.length || input.value.trim() !== query) return;
        titles.forEach((title) => {
          const option = document.createElement("button");
          option.type = "button";
          option.className = "search-suggestion";
          option.setAttribute("role", "option");
          option.textContent = title;
          option.addEventListener("click", () => {
            input.value = title;
            suggestions.hidden = true;
            suggestions.replaceChildren();
            input.focus();
          });
          suggestions.appendChild(option);
        });
        suggestions.hidden = false;
      } catch (error) {
        if (error.name !== "AbortError") console.debug("Sugestões indisponíveis:", error);
      }
    }, 500);
  });

  input.addEventListener("blur", () => {
    setTimeout(() => { suggestions.hidden = true; }, 150);
  });
}

function friendlyError(status, detail) {
  const messages = {
    400: "O URL ou os parâmetros enviados são inválidos.",
    403: "A operação foi recusada por motivos de segurança.",
    404: "O conteúdo solicitado não foi encontrado.",
    422: "Os dados enviados não são válidos.",
    429: "Muitas requisições. Aguarde um pouco e tente novamente.",
    500: "O servidor não conseguiu concluir a operação.",
    502: "A fonte externa não respondeu corretamente.",
    503: "A fonte está temporariamente indisponível."
  };
  return detail || messages[status] || "Não foi possível concluir a operação.";
}

async function requestJson(url, options = {}, timeoutMs = 30000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
      credentials: "same-origin"
    });
    const contentType = response.headers.get("content-type") || "";
    const payload = contentType.includes("application/json") ? await response.json() : null;
    if (!response.ok) {
      throw new Error(friendlyError(response.status, payload?.detail));
    }
    return payload;
  } catch (error) {
    if (error.name === "AbortError") throw new Error("A operação demorou demasiado. Tente novamente.");
    if (error instanceof TypeError) throw new Error("Não foi possível ligar ao backend.");
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

function setBusy(button, busy, text) {
  if (!button) return;
  if (busy) {
    button.dataset.originalText = button.textContent;
    button.disabled = true;
    button.textContent = text;
  } else {
    button.disabled = false;
    button.textContent = button.dataset.originalText || button.textContent;
  }
}

function formatDuration(seconds) {
  if (!Number.isFinite(Number(seconds))) return "Duração não informada";
  const total = Number(seconds);
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[character]));
}

function setupHome(form) {
  const query = document.getElementById("home-query");
  const button = document.getElementById("home-submit");
  const status = document.getElementById("home-status");
  const result = document.getElementById("home-result");

  form.addEventListener("submit", async (event) => {
    const value = query.value.trim();
    if (!/^https?:\/\//i.test(value)) return;
    event.preventDefault();
    status.hidden = false;
    result.hidden = true;
    status.textContent = "Detectando plataforma...";
    setBusy(button, true, "Processando...");
    try {
      const detected = await requestJson(`/api/multi/detect?url=${encodeURIComponent(value)}`);
      if (!detected?.valid) throw new Error("URL inválido ou plataforma não suportada.");
      status.textContent = `${detected.platform_name} detectado. Obtendo informações...`;
      const metadata = await requestJson("/api/multi/metadata", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url: value })
      });
      renderMetadata(result, metadata, value);
      status.hidden = true;
    } catch (error) {
      status.textContent = error.message;
    } finally {
      setBusy(button, false);
    }
  });
}

function renderMetadata(container, data, url) {
  const formats = (data.allowed_formats || []).join(", ").toUpperCase() || "Não informado";
  const thumbnail = data.thumbnail
    ? `<img class="card-thumb-image" src="${escapeHtml(data.thumbnail)}" alt="${escapeHtml(data.title)}">`
    : "";
  const platform = String(data.platform_name || data.platform || "");
  const isAudioOnlyPlatform = ["Facebook", "Instagram", "TikTok", "XVideos"].includes(platform);
  const actionsHtml = isAudioOnlyPlatform
    ? `<div class="card-actions"><a class="btn-card primary" href="/download-page?url=${encodeURIComponent(url)}">Baixar diretamente</a></div>`
    : `<div class="card-actions"><a class="btn-card" href="/player?url=${encodeURIComponent(url)}">Ouvir</a><a class="btn-card primary" href="/download-page?url=${encodeURIComponent(url)}">Configurar download</a></div>`;

  container.innerHTML = `
    <div class="card-thumb">${thumbnail}</div>
    <div class="card-body">
      <h2 class="card-title">${escapeHtml(data.title || "Sem título")}</h2>
      <p class="card-author">${escapeHtml(data.uploader || "Autor não informado")}</p>
      <div class="card-meta">
        <span>${escapeHtml(platform)}</span>
        <span>${escapeHtml(formatDuration(data.duration))}</span>
        <span>${escapeHtml(formats)}</span>
      </div>
      ${data.view_count ? `<p class="card-author">${escapeHtml(data.view_count)} visualizações</p>` : ""}
      ${actionsHtml}
      <div class="download-form-inline">
        <select data-file-type aria-label="Formato">
          ${(data.allowed_formats || ["mp4"]).map((format) => `<option value="${escapeHtml(format)}">${escapeHtml(format.toUpperCase())}</option>`).join("")}
        </select>
        <select data-quality aria-label="Qualidade">
          <option value="best">Melhor qualidade</option>
          <option value="1080p">1080p</option>
          <option value="720p">720p</option>
          <option value="480p">480p</option>
          <option value="360p">360p</option>
          <option value="320">320 kbps</option>
          <option value="192">192 kbps</option>
          <option value="128">128 kbps</option>
        </select>
        <button class="btn-search" type="button" data-download>Baixar agora</button>
      </div>
      <p class="download-feedback" data-feedback role="status"></p>
    </div>`;
  container.hidden = false;

  const type = container.querySelector("[data-file-type]");
  const quality = container.querySelector("[data-quality]");
  const downloadButton = container.querySelector("[data-download]");
  type.addEventListener("change", () => {
    const audio = type.value === "mp3";
    quality.innerHTML = audio
      ? '<option value="best">Melhor qualidade</option><option value="320">320 kbps</option><option value="192">192 kbps</option><option value="128">128 kbps</option>'
      : '<option value="best">Melhor qualidade</option><option value="1080p">1080p</option><option value="720p">720p</option><option value="480p">480p</option><option value="360p">360p</option>';
  });
  downloadButton.addEventListener("click", () => downloadBlob(url, type.value, quality.value, downloadButton, container.querySelector("[data-feedback]")));
}

async function downloadBlob(url, fileType, quality, button, feedback) {
  setBusy(button, true, "Baixando...");
  feedback.textContent = "Preparando download...";
  try {
    const response = await fetch("/api/multi/download", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "same-origin",
      body: JSON.stringify({ url, file_type: fileType, quality })
    });
    if (!response.ok) {
      let detail;
      try { detail = (await response.json()).detail; } catch (_) { /* non-JSON error */ }
      throw new Error(friendlyError(response.status, detail));
    }
    const blob = await response.blob();
    const disposition = response.headers.get("Content-Disposition") || "";
    const filename = disposition.match(/filename="?([^";]+)"?/i)?.[1] || `download.${fileType}`;
    const objectUrl = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = objectUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(objectUrl);
    feedback.textContent = "Download concluído.";
  } catch (error) {
    feedback.textContent = error.message || "Não foi possível baixar o conteúdo.";
  } finally {
    setBusy(button, false);
  }
}
