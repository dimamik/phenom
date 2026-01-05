# Changelog

All notable changes to the installer itself will be documented in this file.
If you're looking for versions of the template itself, please refer to the commit history
of the [template repository](https://github.com/dimamik/phenom).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.1

### Fix
- Correctly rename `.bat` and `.yml` files when running `mix phenom.new`


## 0.2.0

- Split up the generator and the template itself. Now the generator lives in the `installer` directory,
  while the template itself remains in the root.
- Improve `mix phenom.new` generator: now we're not leaving any leftovers from the installer in the generated project. Also, the only real dependency of this library is [template repository](https://github.com/dimamik/phenom) itself, making it tiny and focused.

## 0.1.0

- Initial release of Phenom
