"""
Módulo central de download usando yt-dlp.
Fornece funções para obter informações, pesquisar, baixar e fazer streaming.
"""
import os
import logging
import urllib.request
import shutil
from pathlib import Path
from typing import Optional, Dict, Any, List

import yt_dlp

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DEFAULT_DOWNLOAD_DIR = Path(__file__).resolve().parent.parent.parent / "downloads"

def _ensure_download_dir(download_dir: Optional[Path] = None) -> Path:
    if download_dir is None:
        download_dir = DEFAULT_DOWNLOAD_DIR
    download_dir.mkdir(parents=True, exist_ok=True)
    return download_dir

def download_thumbnail(thumbnail_url: str, output_dir: Path, base_filename: str) -> Optional[Path]:
    """
    Baixa a thumbnail do vídeo e guarda no diretório de downloads.
    Retorna o caminho do ficheiro da imagem ou None se falhar.
    """
    if not thumbnail_url:
        return None
    try:
        ext = os.path.splitext(thumbnail_url.split('?')[0])[1] or '.jpg'
        thumbnail_path = output_dir / f"{base_filename}{ext}"
        with urllib.request.urlopen(thumbnail_url) as response, open(thumbnail_path, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
        logger.info(f"Thumbnail guardada em: {thumbnail_path}")
        return thumbnail_path
    except Exception as e:
        logger.error(f"Erro ao baixar thumbnail: {e}")
        return None

def search_youtube(query: str, max_results: int = 100) -> List[Dict[str, Any]]:
    """
    Pesquisa vídeos no YouTube usando yt-dlp.
    """
    search_url = f"ytsearch{max_results}:{query}"
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'extract_flat': 'in_playlist',
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(search_url, download=False)
            
            results = []
            if info and 'entries' in info:
                for entry in info['entries']:
                    if entry:
                        video_id = entry.get('id')
                        
                        thumbnail = entry.get('thumbnail')
                        if not thumbnail:
                            thumbs = entry.get('thumbnails') or []
                            if thumbs:
                                best = max(thumbs, key=lambda t: (int(t.get('width') or 0) * int(t.get('height') or 0), t.get('url') or ''))
                                thumbnail = best.get('url') if isinstance(best, dict) else None
                        if not thumbnail and video_id:
                            thumbnail = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"
                        
                        results.append({
                            'id': video_id,
                            'title': entry.get('title'),
                            'url': f"https://www.youtube.com/watch?v={video_id}",
                            'thumbnail': thumbnail,
                            'duration': entry.get('duration'),
                            'uploader': entry.get('uploader') or entry.get('channel'),
                            'view_count': entry.get('view_count'),
                        })
            
            logger.info(f"Pesquisa '{query}' retornou {len(results)} resultados")
            return results
    except Exception as e:
        logger.error(f"Erro na pesquisa do YouTube: {e}")
        raise

def _best_thumbnail(info: Dict[str, Any]) -> Optional[str]:
    """Retorna a melhor thumbnail disponível para um vídeo ou reel."""
    explicit = info.get('thumbnail')
    if explicit:
        return explicit

    thumbnails = info.get('thumbnails') or []
    best_thumb = None
    best_score = -1
    for thumb in thumbnails:
        if not isinstance(thumb, dict):
            continue
        url = thumb.get('url')
        if not url:
            continue
        width = int(thumb.get('width') or 0)
        height = int(thumb.get('height') or 0)
        score = width * height
        if score > best_score:
            best_score = score
            best_thumb = url
    return best_thumb


def get_video_info(url: str) -> Dict[str, Any]:
    """
    Obtém informações detalhadas do vídeo.
    """
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            return {
                'id': info.get('id'),
                'title': info.get('title'),
                'duration': info.get('duration'),
                'thumbnail': _best_thumbnail(info),
                'uploader': info.get('uploader'),
                'view_count': info.get('view_count'),
                'formats': [
                    {
                        'format_id': f.get('format_id'),
                        'ext': f.get('ext'),
                        'resolution': f.get('resolution'),
                        'filesize': f.get('filesize') or f.get('filesize_approx'),
                        'vcodec': f.get('vcodec'),
                        'acodec': f.get('acodec'),
                        'format_note': f.get('format_note'),
                    }
                    for f in info.get('formats', [])
                    if f.get('vcodec') != 'none' or f.get('acodec') != 'none'
                ]
            }
    except Exception as e:
        logger.error(f"Erro ao obter informações do vídeo {url}: {e}")
        raise

def get_stream_url(url: str, stream_type: str = 'audio') -> Dict[str, Any]:
    """
    Obtém URL de streaming direto para ouvir/assistir sem baixar completamente.
    
    Args:
        url: URL do vídeo.
        stream_type: 'audio' para apenas áudio, 'video' para vídeo completo.
    
    Returns:
        Dicionário com URL de streaming e informações.
    """
    # Primeiro, obter informações completas do vídeo sem especificar formato
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            
            stream_info = {
                'title': info.get('title'),
                'duration': info.get('duration'),
                'thumbnail': info.get('thumbnail'),
                'uploader': info.get('uploader'),
                'stream_url': None,
                'type': stream_type,
                'ext': None,
            }
            
            # Obter lista de formatos disponíveis
            formats = info.get('formats', [])
            
            # Filtrar formatos que têm URL direto
            valid_formats = [f for f in formats if f.get('url')]
            
            if stream_type == 'audio':
                # Para áudio: procurar formatos apenas de áudio
                audio_formats = [
                    f for f in valid_formats 
                    if f.get('acodec') != 'none' and f.get('vcodec') == 'none'
                ]
                
                if audio_formats:
                    # Escolher o melhor formato de áudio
                    best_audio = audio_formats[0]
                    # Tentar encontrar o de melhor qualidade
                    for fmt in audio_formats:
                        if fmt.get('abr') and (not best_audio.get('abr') or fmt['abr'] > best_audio['abr']):
                            best_audio = fmt
                    
                    stream_info['stream_url'] = best_audio['url']
                    stream_info['ext'] = best_audio.get('ext', 'm4a')
                elif valid_formats:
                    # Se não houver áudio puro, usar o primeiro formato válido
                    stream_info['stream_url'] = valid_formats[0]['url']
                    stream_info['ext'] = valid_formats[0].get('ext', 'm4a')
            else:
                # Para vídeo: procurar formatos progressivos (com áudio e vídeo)
                progressive_formats = [
                    f for f in valid_formats 
                    if f.get('vcodec') != 'none' and f.get('acodec') != 'none'
                ]
                
                if progressive_formats:
                    # Escolher o melhor formato progressivo
                    best_video = progressive_formats[0]
                    for fmt in progressive_formats:
                        # Preferir MP4
                        if fmt.get('ext') == 'mp4' and best_video.get('ext') != 'mp4':
                            best_video = fmt
                        # Se ambos são MP4, escolher maior resolução
                        elif fmt.get('ext') == 'mp4' and best_video.get('ext') == 'mp4':
                            if fmt.get('height', 0) > best_video.get('height', 0):
                                best_video = fmt
                    
                    stream_info['stream_url'] = best_video['url']
                    stream_info['ext'] = best_video.get('ext', 'mp4')
                else:
                    # Se não houver progressivo, procurar qualquer vídeo
                    video_formats = [
                        f for f in valid_formats 
                        if f.get('vcodec') != 'none'
                    ]
                    
                    if video_formats:
                        stream_info['stream_url'] = video_formats[0]['url']
                        stream_info['ext'] = video_formats[0].get('ext', 'mp4')
                    elif valid_formats:
                        # Último recurso: usar primeiro formato disponível
                        stream_info['stream_url'] = valid_formats[0]['url']
                        stream_info['ext'] = valid_formats[0].get('ext', 'mp4')
            
            # Verificar se encontrou URL válido
            if not stream_info['stream_url']:
                logger.error(f"Não foi possível obter URL de streaming para {url}")
                raise Exception("Não foi possível obter URL de streaming. Este vídeo pode não permitir streaming direto.")
            
            logger.info(f"Stream URL obtido para {url} (tipo: {stream_type}, extensão: {stream_info['ext']})")
            return stream_info
    except Exception as e:
        logger.error(f"Erro ao obter stream URL: {e}")
        raise

def download_video(
    url: str,
    output_dir: Optional[Path] = None,
    format_id: Optional[str] = None,
    audio_only: bool = False,
    audio_quality: str = "192",
    embed_thumbnail: bool = True,
) -> Path:
    """
    Baixa o vídeo (ou áudio) do URL fornecedor.
    """
    output_dir = _ensure_download_dir(output_dir)
    outtmpl = str(output_dir / "%(title).150s [%(id)s].%(ext)s")
    
    ydl_opts = {
        'outtmpl': outtmpl,
        'noplaylist': True,
        'quiet': True,
        'no_warnings': True,
        'progress_hooks': [],
    }
    
    if audio_only:
        ydl_opts.update({
            'format': 'bestaudio/best',
            'writethumbnail': embed_thumbnail,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': audio_quality,
            }],
        })
        if embed_thumbnail:
            ydl_opts['postprocessors'].append({'key': 'EmbedThumbnail'})
    else:
        if format_id:
            ydl_opts['format'] = format_id
        else:
            ydl_opts['format'] = 'bestvideo+bestaudio/best'
        ydl_opts['merge_output_format'] = 'mp4'
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            filepath = ydl.prepare_filename(info)
            if audio_only:
                filepath = str(Path(filepath).with_suffix('.mp3'))
            elif ydl_opts.get('merge_output_format') == 'mp4':
                filepath = str(Path(filepath).with_suffix('.mp4'))
            elif format_id:
                final_ext = info.get('ext', 'mp4')
                filepath = str(Path(filepath).with_suffix(f'.{final_ext}'))
            
            logger.info(f"Download concluído: {filepath}")
            return Path(filepath)
    except Exception as e:
        logger.error(f"Erro no download do vídeo {url}: {e}")
        raise

def list_formats(url: str) -> list:
    """
    Lista formatos disponíveis para download.
    """
    info = get_video_info(url)
    return info.get('formats', [])

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        url = sys.argv[1]
        print("Obtendo informações...")
        infos = get_video_info(url)
        print(f"Título: {infos['title']}")
        print(f"Duração: {infos['duration']}s")
        print("Formatos disponíveis:")
        for fmt in infos['formats'][:10]:
            print(f"  {fmt['format_id']} - {fmt['ext']} - {fmt.get('resolution')} - {fmt.get('format_note')}")
        print("\nBaixando vídeo...")
        path = download_video(url, audio_only=False)
        print(f"Arquivo salvo em: {path}")
    else:
        print("Uso: python -m app.core.downloader <URL>")
