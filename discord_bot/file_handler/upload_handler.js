const axios = require('axios');
const AdmZip = require('adm-zip');
const tar = require('tar-stream');
const zlib = require('zlib');
const { Readable } = require('stream');

async function extractFiles(file) {
  console.log(`[FileHandler] Extracting file: ${file.name}`);

  try {
    const response = await axios.get(file.url, {
      responseType: 'arraybuffer'
    });

    const buffer = Buffer.from(response.data);
    const fileName = file.name.toLowerCase();

    if (fileName.endsWith('.lua')) {
      return {
        files: [{
          name: file.name,
          content: buffer.toString('utf8'),
          size: buffer.length,
          type: 'lua'
        }],
        totalSize: buffer.length
      };
    }

    if (fileName.endsWith('.zip')) {
      return await extractZip(buffer);
    }

    if (fileName.endsWith('.tar.gz') || fileName.endsWith('.tgz')) {
      return await extractTarGz(buffer);
    }

    if (fileName.endsWith('.tar')) {
      return await extractTar(buffer);
    }

    throw new Error(`Unsupported file format: ${fileName}`);
  } catch (error) {
    console.error('[FileHandler] Error extracting files:', error);
    throw new Error(`Failed to extract files: ${error.message}`);
  }
}

async function extractZip(buffer) {
  try {
    const zip = new AdmZip(buffer);
    const zipEntries = zip.getEntries();
    
    const files = [];
    let totalSize = 0;

    for (const entry of zipEntries) {
      if (!entry.isDirectory && entry.entryName.endsWith('.lua')) {
        const content = entry.getData().toString('utf8');
        files.push({
          name: entry.entryName,
          content: content,
          size: content.length,
          type: 'lua'
        });
        totalSize += content.length;
      }
    }

    console.log(`[FileHandler] Extracted ${files.length} Lua files from ZIP`);
    
    return {
      files: files,
      totalSize: totalSize
    };
  } catch (error) {
    throw new Error(`ZIP extraction failed: ${error.message}`);
  }
}

async function extractTarGz(buffer) {
  try {
    const gunzipped = zlib.gunzipSync(buffer);
    return await extractTar(gunzipped);
  } catch (error) {
    throw new Error(`TAR.GZ extraction failed: ${error.message}`);
  }
}

async function extractTar(buffer) {
  return new Promise((resolve, reject) => {
    const extract = tar.extract();
    const files = [];
    let totalSize = 0;

    extract.on('entry', (header, stream, next) => {
      if (header.type === 'file' && header.name.endsWith('.lua')) {
        const chunks = [];
        
        stream.on('data', chunk => {
          chunks.push(chunk);
        });

        stream.on('end', () => {
          const content = Buffer.concat(chunks).toString('utf8');
          files.push({
            name: header.name,
            content: content,
            size: content.length,
            type: 'lua'
          });
          totalSize += content.length;
          next();
        });

        stream.resume();
      } else {
        stream.on('end', () => {
          next();
        });
        stream.resume();
      }
    });

    extract.on('finish', () => {
      console.log(`[FileHandler] Extracted ${files.length} Lua files from TAR`);
      resolve({
        files: files,
        totalSize: totalSize
      });
    });

    extract.on('error', error => {
      reject(new Error(`TAR extraction failed: ${error.message}`));
    });

    const readable = Readable.from(buffer);
    readable.pipe(extract);
  });
}

function validateLuaFile(content) {
  if (!content || content.trim().length === 0) {
    return { valid: false, error: 'Empty file' };
  }

  const suspiciousPatterns = [
    { pattern: /\x00/g, name: 'null bytes' },
    { pattern: /\x1b/g, name: 'escape characters' }
  ];

  for (const { pattern, name } of suspiciousPatterns) {
    if (pattern.test(content)) {
      return { valid: false, error: `Contains suspicious ${name}` };
    }
  }

  return { valid: true };
}

module.exports = {
  extractFiles,
  extractZip,
  extractTarGz,
  extractTar,
  validateLuaFile
};
