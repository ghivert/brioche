export function reject() {
  return Promise.reject()
}

export function pending() {
  return new Promise(resolve => {
    setTimeout(resolve, 100)
  })
}
