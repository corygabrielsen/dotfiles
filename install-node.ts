#!/usr/bin/env node

import * as fs from 'fs'
import * as path from 'path'

interface SubConfig {
  colorize: string
  files: string[]
}

interface Config {
  [folder: string]: SubConfig
}

const HOME: string =
  process.env.HOME ||
  (() => {
    throw new Error('Environment variable HOME not set')
  })()
const CONFIG: Config = JSON.parse(fs.readFileSync('configuration-data.json', 'utf8'))

function longest(configuration: Config): number {
  /**
   * Returns the length of the longest folder + file name combo
   */
  let maxlen: number = 0
  Object.entries(configuration).forEach(([_, subconfig]) => {
    // close but buggy: maxlen = Math.max(maxlen, ...files.map((file) => `${HOME}/.${file}`.length));
    subconfig.files.forEach((file) => {
      maxlen = Math.max(maxlen, `${HOME}/.${file}`.length)
    })
  })
  return maxlen
}

const DOTFILES_REPO_ROOT = fs.realpathSync(path.resolve(__dirname))

const LJUST = longest(CONFIG)

for (const [folder, files] of Object.entries(CONFIG)) {
  for (const file of files['files']) {
    const src = path.join(DOTFILES_REPO_ROOT, folder, file)
    const dest = path.join(HOME, `.${file}`)

    try {
      fs.unlinkSync(dest)
    } catch {
      // do nothing
    }

    console.log(`${dest.padEnd(LJUST)} ---> ${src}`)
    fs.symlinkSync(src, dest)
  }
}
