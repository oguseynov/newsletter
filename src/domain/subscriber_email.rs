use validator::Validate;

#[derive(Debug, Validate)]
pub struct SubscriberEmail {
    #[validate(email)]
    value: String,
}

impl SubscriberEmail {
    pub fn parse(s: String) -> Result<SubscriberEmail, String> {
        let email = SubscriberEmail { value: s };
        match email.validate() {
            Ok(_) => Ok(email),
            Err(_) => Err("Invalid email address.".to_string()),
        }
    }
}

impl AsRef<str> for SubscriberEmail {
    fn as_ref(&self) -> &str {
        &self.value
    }
}

#[cfg(test)]
mod tests {
    use super::SubscriberEmail;
    use claim::{assert_err, assert_ok};

    #[test]
    fn empty_string_is_rejected() {
        let email = "".to_string();
        assert_err!(SubscriberEmail::parse(email));
    }

    #[test]
    fn email_missing_at_symbol_is_rejected() {
        let email = "testexample.com".to_string();
        assert_err!(SubscriberEmail::parse(email));
    }

    #[test]
    fn email_missing_subject_is_rejected() {
        let email = "@example.com".to_string();
        assert_err!(SubscriberEmail::parse(email));
    }

    #[test]
    fn valid_email_is_accepted() {
        let email = "test@example.com".to_string();
        assert_ok!(SubscriberEmail::parse(email));
    }
}
