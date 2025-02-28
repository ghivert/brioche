export function satisfies(version, range) {
  return Bun.semver.satisfies(version, range)
}

export function compare(versionA, versionB) {
  return Bun.semver.order(versionA, versionB)
}
